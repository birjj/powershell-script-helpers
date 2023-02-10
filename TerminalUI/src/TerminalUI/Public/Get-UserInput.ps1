$MockableHost = $Host
$MockableConsole = [System.Console]

<#
.SYNOPSIS
    Prompts the user for text input. Similar to Read-Host, but with suggestions support.
.DESCRIPTION
    Prompts the user for text input on the CLI.
    Supports all parameters from the built-in Read-Host (except -AsSecureString), as well as suggestions.
.EXAMPLE
    C:\PS> Get-UserInput
    # user is shown an empty line. Whatever they write will be returned after they press enter
.EXAMPLE
    C:\PS> Get-UserInput -Prompt 'Test'
    # user is shown a line containing 'Test: '. Whatever they write will be returned after they press enter
.EXAMPLE
    C:\PS> Get-UserInput -Prompt 'Password' -MaskInput
    # Whatever the user writes will be shown as a list of '*'. The returned value will be what the user entered
.EXAMPLE
    C:\PS> Get-UserInput -Prompt 'Choose a color' -Suggestions 'Blue','Red','Green'
    # The user is free to write whatever they want, but will be shown suggestions as they type
.PARAMETER Prompt
    An optional text for the prompt. The function appends a colon (`:`) to the text you enter, and displays it in bold to differentiate it from the users input.
.PARAMETER Suggestions
    A list of strings to use as suggestions to the user. The user will be shown these, and can autocomplete them, but is also free to enter their own values.
    Suggestions can be a list of strings, or a list of `[UserInputSuggestion]` if you want more control over how they are presented to the user.
.PARAMETER NoHelp
    If set, don't show the user how to use the prompt (i.e. '[↑↓] Change suggestion  [Tab] Pick suggestion  [Enter] Submit  [Esc] Cancel').
    Only relevant if `-Suggestions` is set, as the help won't be shown without suggestions.
.OUTPUTS
    The string the user entered.
#>
function Get-UserInput {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Prompt', Justification = 'False positive')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'MaxSuggestions', Justification = 'False positive')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'MaskInput', Justification = 'False positive')]
    param(
        [string] $Prompt = '',
        [object[]] $Suggestions = @(),
        [int] $MaxSuggestions = 3,
        [switch] $NoHelp,
        [switch] $MaskInput
    )

    # normalize suggestions into a list of [UserInputSuggestion]s
    $Suggestions = $Suggestions | ForEach-Object {
        if ($_ -is [UserInputSuggestion]) {
            return $_
        } else {
            return New-UserInputSuggestion ([string] $_)
        }
    }
    if ($null -eq $Suggestions) {
        # the above can return null, because PowerShell
        $Suggestions = @()
    }

    # we use a state hashtable to keep track of the prompt
    $state = @{
        Input                = ""
        CursorIndex          = 0
        SuggestionIndex      = 0
        Suggestions          = @()
        LastSuggestionsCount = 0 # used to erase previous list of suggestions
        Cancelled            = $false
    }

    # writes the complete prompt to the CLI, including suggestions. Puts the cursor at the prompt afterwards
    function Write-Prompt {
        $esc = [char]27
        $text = "";
        $promptLen = $text.Length
        if ($Prompt) {
            $text += "$($PSStyle.Foreground.White)$($PSStyle.Bold)${Prompt}:$($PSStyle.Reset) "
            $promptLen += $Prompt.Length + 2
        }
        if ($MaskInput) {
            $text += '*' * $state.Input.Length
        } else {
            $text += $state.Input
        }
        Write-Host "`r$text$esc[0K" # $esc[0K = erase from cursor to end of line
        Write-ClearSuggestions
        Write-Suggestions
        $MockableConsole::SetCursorPosition($promptLen + $state.CursorIndex, $MockableConsole::CursorTop)
    }

    # writes suggestions from the current line onwards. Puts the cursor at the start of the line it was at previously afterwards.
    function Write-Suggestions {
        $suggestionsPrefix = 'Suggestions: '
        $suggestionsWindowStart = [math]::Max(
            0,
            [math]::Min(
                $state.Suggestions.Length - $MaxSuggestions,
                $state.SuggestionIndex - 1
            )
        );
        $shownSuggestions = $state.Suggestions[$suggestionsWindowStart..($suggestionsWindowStart + $MaxSuggestions - 1)]
        for ($i = 0; $i -lt $shownSuggestions.Length; ++$i) {
            $suggestion = $shownSuggestions[$i]
            $color = [System.ConsoleColor]::DarkGray
            $name = $suggestion.Display
            $text = ''
            if ($i -eq 0) {
                $text += $suggestionsPrefix
                $indent = 2
            } else {
                $indent = "${suggestionsPrefix}> ".Length
            }
            if ($suggestion -eq $state.Suggestions[$state.SuggestionIndex]) {
                $indent = [math]::Max($indent - 2, 0)
                $name = "> $name"
            }
            $text += (' ' * $indent) + $name
            Write-Host -ForegroundColor $color $text
        }
        $MockableConsole::SetCursorPosition(0, $MockableConsole::CursorTop - $shownSuggestions.Length - 1)
        $state.LastSuggestionsCount = $shownSuggestions.Length
    }

    # clears any previously written suggestions from the host output. Puts the cursor at the start of the line it was at previously afterwards.
    function Write-ClearSuggestions {
        $esc = [char]27
        for ($i = 0; $i -lt $state.LastSuggestionsCount; ++$i) {
            Write-Host "$esc[2K"
        }
        $MockableConsole::SetCursorPosition(0, $MockableConsole::CursorTop - $state.LastSuggestionsCount)
    }

    # sets the suggestions-related state to their appropriate values
    function Set-Suggestions {
        $state.Suggestions = @($Suggestions | Where-Object { $_.Value.StartsWith($state.Input) -and $_.Value -ne $state.Input })
        $state.SuggestionIndex = [math]::Max(0, [math]::Min($state.Suggestions.Length - 1, $state.SuggestionIndex))
    }

    # run through our prompt drawing loop
    try {
        # https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
        $key = 0
        $VK_Backspace = 0x08
        $VK_Delete = 0x2E
        $VK_Tab = 0x09
        $VK_End = 0x23
        $VK_Home = 0x24
        $VK_Return = 0x0D
        $VK_Esc = 0x1B
        $VK_Left = 0x25
        $VK_Right = 0x27
        $VK_Down = 0x28
        $VK_Up = 0x26

        if ($suggestions.Length -and -Not $NoHelp) {
            $help = '[↑↓] Change suggestion  [Tab] Pick suggestion  [Enter] Submit  [Esc] Cancel'
            Write-Host -ForegroundColor DarkGray $help
        }

        while ($key.VirtualKeyCode -ne $VK_Return -and $state.Cancelled -eq $false) {
            Set-Suggestions
            $MockableConsole::CursorVisible = $false
            Write-Prompt
            $MockableConsole::CursorVisible = $true
            $key = $MockableHost.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            switch ($key.VirtualKeyCode) {
                $VK_Esc {
                    $state.Cancelled = $true
                }
                $VK_Left {
                    $state.CursorIndex = [math]::Max($state.CursorIndex - 1, 0)
                }
                $VK_Right {
                    $state.CursorIndex = [math]::Min($state.CursorIndex + 1, $state.Input.Length)
                }
                $VK_Down {
                    $state.SuggestionIndex = [math]::Min($state.Suggestions.Length - 1, $state.SuggestionIndex + 1)
                }
                $VK_Up {
                    $state.SuggestionIndex = [math]::Max(0, $state.SuggestionIndex - 1)
                }
                $VK_End {
                    $state.CursorIndex = $state.Input.Length
                }
                $VK_Home {
                    $state.CursorIndex = 0
                }
                $VK_Tab {
                    if ($state.Suggestions.Length) {
                        $state.Input = $state.Suggestions[$state.SuggestionIndex].Value
                        $state.CursorIndex = $state.Input.Length
                    }
                }
                $VK_Backspace {
                    if ($state.CursorIndex -ne 0) {
                        $state.Input = $state.Input.Remove($state.CursorIndex - 1, 1)
                        $state.CursorIndex -= 1
                    }
                }
                $VK_Delete {
                    if ($state.CursorIndex -ne $state.Input.Length) {
                        $state.Input = $state.Input.Remove($state.CursorIndex, 1)
                    }
                }
                $VK_Return {}
                Default {
                    if ($key.Character -and $key.Character -ne "\u0000") {
                        $state.Input += $key.Character
                        $state.CursorIndex += $key.Character.Length
                    }
                }
            }
        }
    } finally {
        $MockableConsole::CursorVisible = $true
        Write-Host ""
        Write-ClearSuggestions
    }

    if ($state.Cancelled) {
        return $null
    }
    return $state.Input
}

