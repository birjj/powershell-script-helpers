$MockableHost = $Host
$MockableConsole = [System.Console]

<#
.SYNOPSIS
    Prompts the user to choose one of multiple options. Similar to $Host.UI.PromptForChoice, but with a different UI and more options.
.DESCRIPTION
    Prompts the user to choose one of multiple options.
    Similar to $Host.UI.PromptForChoice, but with a different UI and more options.
.EXAMPLE
    C:\PS> Get-UserChoice 'Foo','Bar','Baz'
    # user is shown a list of options ('Foo', 'Bar' and 'Baz'), of which they can pick one
    # return value will be the one they choose
.EXAMPLE
    C:\PS> Get-UserChoice 'Foo','Bar','Baz' -Multi
    # user is shown a list of options ('Foo', 'Bar' and 'Baz'), of which they can pick multiple
    # return value will be a list of the ones they choose
.PARAMETER Items
    A list of options the user can pick from. The user will be shown these, and can choose one (or more, if -Multi is set).
    Items can be a list of strings, or a list of `[UserChoiceItem]` if you want more control over how they are presented to the user.
.PARAMETER NoHelp
    If set, don't show the user how to use the prompt (e.g. '[↑↓] Move  [Enter] Submit  [Esc] Cancel').
.OUTPUTS
    The value the user picked, or a list of values if -Multi is set.
#>
function Get-UserChoice {
    param(
        [Parameter(Mandatory = $true)][object[]] $Items,
        [switch] $Multi,
        [switch] $NoHelp
    )

    # abort early if we don't have any options to choose from
    if (-not $Items -or ($Items.Count -eq 0)) {
        if ($Multi) { return @() }
        return $null
    }

    # convert $Items to array of UserChoiceItem's
    $Items = @($Items | ForEach-Object {
            if ($_ -is [UserChoiceItem]) {
                return $_
            } else {
                return New-UserChoiceItem ([string] $_)
            }
        })

    # and setup rest of the state we use
    $Selection = @($Items | ForEach-Object { $false })
    $Cancelled = $false
    $ActiveLine = 0

    function Write-Menu {
        param(
            [int] $ActiveLine
        )
        for ($i = 0; $i -lt $Items.length; ++$i) {
            $Color = [System.ConsoleColor]::Gray
            $Prefix = '>'
            if ($Multi -and $Selection[$i]) {
                $Prefix = '- [x]'
            } elseif ($Multi) {
                $Prefix = '- [ ]'
            }
            $Text = "$prefix $($Items[$i].Display)"
            if ($i -eq $ActiveLine) {
                $Color = [System.ConsoleColor]::DarkGreen
            }
            Write-Host -ForegroundColor $Color $Text
        }
    }

    # run through our menu drawing loop
    try {
        $MockableConsole::CursorVisible = $false
        # https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
        $Key = 0
        $VK_Return = 0x0D
        $VK_Esc = 0x1B
        $VK_Space = 0x20
        $VK_Left = 0x25
        $VK_Right = 0x27
        $VK_Down = 0x28
        $VK_Up = 0x26

        if (-Not $NoHelp) {
            $Help = '[↑↓] Move'
            if ($Multi) {
                $Help += '  [Space] Toggle'
                $Help += '  [Enter] Submit (min 1 selection)'
            } else {
                $Help += '  [Enter/Space] Submit'
            }
            $Help += '  [Esc] Cancel'
            Write-Host -ForegroundColor DarkGray $Help
        }

        while ($Key -ne $VK_Esc) {
            if ($Key -eq $VK_Return) {
                $numChoices = ($Selection | Where-Object { $_ }).Count
                if (-not $Multi -or $numChoices -gt 0) {
                    break
                }
            }
            Write-Menu $ActiveLine
            $MockableConsole::SetCursorPosition(0, $MockableConsole::CursorTop - $Items.Length)
            $Key = $MockableHost.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
            switch ($Key) {
                $VK_Up {
                    $ActiveLine = [math]::Max($ActiveLine - 1, 0)
                }
                $VK_Down {
                    $ActiveLine = [math]::Min($ActiveLine + 1, $Items.Length - 1)
                }
                $VK_Left {
                    $ActiveLine = 0
                }
                $VK_Right {
                    $ActiveLine = $Items.Length - 1
                }
                $VK_Space {
                    if ($Multi) {
                        $Selection[$ActiveLine] = !$Selection[$ActiveLine]
                    } else {
                        $Key = $VK_Return
                    }
                }
                $VK_Esc {
                    $Cancelled = $true
                }
            }
        }
    } finally {
        $MockableConsole::SetCursorPosition(0, $MockableConsole::CursorTop + $Items.Length)
        $MockableConsole::CursorVisible = $true
    }

    if ($Cancelled) {
        return $null
    } elseif ($Multi) {
        $i = 0
        return @($Items
            | Where-Object { $i++; return $Selection[$i - 1] }
            | ForEach-Object { $_.Value })
    } else {
        return $Items[$ActiveLine].Value
    }
}
