# shows an interactive UI for the user to pick an option from
# returns null if user cancels the prompt
function Get-UserChoice {
    param(
        # The list of strings or ChoiceItems to choose between
        [ChoiceItem[]] $items,
        # If set, multiple values can be chosen. Returns an array of values
        [switch] $Multi,
        # If set, don't print the help text
        [switch] $NoHelp
    )

    # convert $items to array of ChoiceItem's
    $items = $items | ForEach-Object {
        if ($_ -is [ChoiceItem]) {
            return $_
        }
        elseif ($_ -is [string]) {
            return [ChoiceItem]::new($_)
        }
    }

    # and setup rest of the state we use
    $selection = $items | ForEach-Object { $false }
    $cancelled = $false
    $active_line = 0

    function Write-Menu {
        param(
            [int] $active_line
        )
        for ($i = 0; $i -lt $items.length; ++$i) {
            $color = [System.ConsoleColor]::Gray
            if ($i -eq $active_line) {
                $color = [System.ConsoleColor]::DarkGreen
            }
            Write-Host -ForegroundColor $color ($items[$i].ToMenuString($selection[$i], $Multi.IsPresent))
        }
    }

    # run through our menu drawing loop
    try {
        [System.Console]::CursorVisible = $false
        # https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
        $key = 0
        $VK_Return = 0x0D
        $VK_Esc = 0x1B
        $VK_Space = 0x20
        $VK_Left = 0x25
        $VK_Right = 0x27
        $VK_Down = 0x28
        $VK_Up = 0x26

        if (-Not $NoHelp) {
            $help = '[↑↓] Move'
            if ($Multi) {
                $help += '  [Space] Toggle'
            }
            $help += '  [Enter] Submit  [Esc] Cancel'
            Write-Host -ForegroundColor DarkGray $help
        }
        
        while ($key -ne $VK_Return -and $key -ne $VK_Esc) {
            Write-Menu $active_line
            [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - $items.Length)
            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
            switch ($key) {
                $VK_Up {
                    $active_line = [math]::Max($active_line - 1, 0)    
                }
                $VK_Down {
                    $active_line = [math]::Min($active_line + 1, $items.Length - 1)
                }
                $VK_Left {
                    $active_line = 0
                }
                $VK_Right {
                    $active_line = $items.Length - 1
                }
                $VK_Space {
                    if ($Multi) {
                        $selection[$active_line] = !$selection[$active_line]
                    }
                    else {
                        $key = $VK_Return
                    }
                }
                $VK_Esc {
                    $cancelled = $true
                }
            }
        }
    }
    finally {
        [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop + $items.Length)
        [System.Console]::CursorVisible = $true
    }

    if ($cancelled) {
        return $null
    }
    elseif ($Multi) {
        return $selection
    }
    else {
        return $items[$active_line].Value
    }
}

class ChoiceItem {
    [string] $Name
    [string] $Description
    [object] $Value

    ChoiceItem([string] $name) {
        $this.Name = $name
        $this.Value = $name
        $this.Description = ''
    }
    ChoiceItem([string] $name, [object] $value) {
        $this.Name = $name
        $this.Value = $value
        $this.Description = ''
    }
    ChoiceItem([string] $name, [object] $value, [string] $description) {
        $this.Name = $name
        $this.Value = $value
        $this.Description = $description
    }

    [string] ToMenuString([switch] $Selected, [switch] $Multi) {
        $prefix = '>'
        if ($Multi -and $Selected) {
            $prefix = '- [x]'
        }
        elseif ($Multi) {
            $prefix = '- [ ]'
        }
        $outp = "$prefix $($this.Name)"
        if ($this.Description) {
            $outp = $outp + " ($($this.Description))"
        }
        return $outp
    }
}
