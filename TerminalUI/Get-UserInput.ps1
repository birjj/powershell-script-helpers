# gets 
function Get-UserInput {
    param(
        # an optional prompt to render before user input
        [string] $prompt = '',
        # an optional list of suggestions to show the user
        [object[]] $suggestions = @(),
        # If set, don't print the help text
        [switch] $NoHelp
    )

    $suggestions = $suggestions | % {
        if ($_ -is [UserInputSuggestion]) {
            return $_
        }
        else {
            return [UserInputSuggestion]::new([string] $_)
        }
    }
    if ($suggestions -eq $null) { $suggestions = @() }

    $state = @{
        Input                = ""
        CursorIndex          = 0
        SuggestionIndex      = 0
        Suggestions          = @()
        LastSuggestionsCount = 0 # used to erase previous list of suggestions
        Cancelled            = $false
    }

    function Write-Prompt {
        $esc = [char]27
        $text = "";
        $promptLen = $text.Length
        if ($prompt) {
            $text += "$($global:PSStyle.Foreground.White)$($global:PSStyle.Bold)${prompt}:$($global:PSStyle.Reset) "
            $promptLen += $prompt.Length + 2
        }
        $text += $state.Input
        if ($state.Suggestions.Length) {
            $fill = $state.Suggestions[$state.SuggestionIndex].Name.Substring($state.Input.Length)
            # $text += "$($global:PSStyle.Foreground.BrightBlack)$($fill)$($global:PSStyle.Reset)"
        }
        Write-Host "`r$text$esc[0K"
        Write-ClearSuggestions
        Write-Suggestions
        [System.Console]::SetCursorPosition($promptLen + $state.CursorIndex, [System.Console]::CursorTop)
    }

    # writes suggestions from the current line onwards
    function Write-Suggestions {
        # write out any suggestions
        for ($i = 0; $i -lt $state.Suggestions.Length; ++$i) {
            $suggestion = $state.Suggestions[$i]
            $color = [System.ConsoleColor]::DarkGray
            $name = $suggestion.ToSuggestionString()
            $text = ''
            if ($i -eq 0) {
                $text += 'Suggestions: '
                $indent = 2
            }
            else {
                $indent = 'Suggestions: > '.Length
            }
            if ($i -eq $state.SuggestionIndex) {
                $indent = [math]::Max($indent - 2, 0)
                $name = "> $name"
            }
            $text += (" " * $indent) + $name
            Write-Host -ForegroundColor $color $text
        }
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - $state.Suggestions.Length - 1)
        $state.LastSuggestionsCount = $state.Suggestions.Length
    }

    # clears any previously written suggestions from the host output
    function Write-ClearSuggestions {
        $esc = [char]27
        for ($i = 0; $i -lt $state.LastSuggestionsCount; ++$i) {
            Write-Host "$esc[2K"
        }
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - $state.LastSuggestionsCount)
    }

    # sets the suggestions-related state to their appropriate values
    function Set-Suggestions {
        $state.Suggestions = $suggestions | Where-Object { $_.Name.StartsWith($state.Input) -and $_.Name -ne $state.Input }
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
            [System.Console]::CursorVisible = $false
            Write-Prompt
            [System.Console]::CursorVisible = $true
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
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
                        $state.Input = $state.Suggestions[$state.SuggestionIndex].Name
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
    }
    finally {
        [System.Console]::CursorVisible = $true
        Write-Host ""
        Write-ClearSuggestions
    }

    if ($state.Cancelled) {
        return $null
    }
    return $state.Input
}

class UserInputSuggestion {
    [string] $Name
    [string] $Description

    UserInputSuggestion([string] $name) {
        $this.Name = $name
        $this.Description = ''
    }
    UserInputSuggestion([string] $name, [string] $description) {
        $this.Name = $name
        $this.Description = $description
    }

    [string] ToSuggestionString() {
        $outp = "$($this.Name)"
        if ($this.Description) {
            $outp += "  ($($this.Description))"
        }
        return $outp
    }
}
