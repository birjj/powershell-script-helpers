Set-Location -Path $PSScriptRoot
$ModuleName = 'TerminalUI'
$PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
    #if the module is already in memory, remove it
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force
#-------------------------------------------------------------------------

InModuleScope 'TerminalUI' {
    BeforeAll {
        function Mock-ReadKey {
            [CmdletBinding()]
            [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
            param (
                [object[]] $Keys = @($VK_Esc)
            )

            [System.Collections.Generic.List[System.Object]]$KeyObjects = $Keys | ForEach-Object {
                $Code = 0x00
                $Char = '\u0000'
                if ($_.GetType().Name -eq 'String') {
                    $Char = $_
                } else {
                    $Code = $_
                }
                return [PSCustomObject]@{
                    VirtualKeyCode = $Code
                    Character      = $Char
                }
            }

            $script:MockableHost = @{
                UI = @{
                    RawUI = New-Object PSObject | Add-Member -MemberType ScriptMethod -Name 'ReadKey' -Value {
                        if (-not $KeyObjects.Length) {
                            throw "Mocked ReadKey was called after every mocked key ($($Keys | ConvertTo-Json -Compress)) was used"
                        }
                        $Key, $Rest = $KeyObjects
                        $KeyObjects.RemoveAt(0)
                        return $Key
                    }.GetNewClosure() -PassThru
                }
            }
        }

        # mock the console so we don't move the cursor around
        class MockConsole {
            static [int] $CursorTop = 0
            static [bool] $CursorVisible = $true
            static [void] SetCursorPosition($x, $y) {}
        }
        $MockableConsole = [MockConsole]
        Mock Write-Host {}

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
        $VK_Space = 0x20
    }

    Describe 'Get-UserInput' -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        } #beforeAll

        Context 'Output' {
            It 'returns the entered string on return' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @('a', 's', 'd', $VK_Return)

                $outp = Get-UserInput
                $outp | Should -BeExactly 'asd'
            }

            It 'returns $null if cancelled' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @('a', 's', 'd', $VK_Esc)

                $outp = Get-UserInput
                $outp | Should -BeExactly $null
            }
        }

        Context 'Suggestions' {
            It 'chooses the first suggestions on [TAB]' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Tab, $VK_Return)

                $outp = Get-UserInput -Suggestions 'Foo', 'Bar'
                $outp | Should -BeExactly 'Foo'
            }

            It 'changes suggestions on [ARROW_DOWN]' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Down, $VK_Tab, $VK_Return)

                $outp = Get-UserInput -Suggestions 'Foo', 'Bar'
                $outp | Should -BeExactly 'Bar'
            }

            It 'changes suggestions on [ARROW_DOWN] beyond the shown suggestions' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Down, $VK_Down, $VK_Down, $VK_Down, $VK_Tab, $VK_Return)

                $outp = Get-UserInput -Suggestions 'Foo', 'Bar', 'Baz', 'Qux', 'Quux' -MaxSuggestions 3
                $outp | Should -BeExactly 'Quux'
            }

            It 'filters suggestions based on input' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @('B', $VK_Tab, $VK_Return)

                $outp = Get-UserInput -Suggestions 'Foo', 'Bar'
                $outp | Should -BeExactly 'Bar'
            }

            It 'picks no suggestion if none match input' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @('C', $VK_Tab, $VK_Return)

                $outp = Get-UserInput -Suggestions 'Foo', 'Bar'
                $outp | Should -BeExactly 'C'
            }
        }
    }

    Describe 'New-UserInputSuggestion' -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        } #beforeAll

        Context 'Output' {
            It 'accepts a single value' {
                $outp = New-UserInputSuggestion 'asd'
                $outp.Value | Should -BeExactly 'asd'
                $outp.Display | Should -BeExactly 'asd'
            }

            It 'accepts two values' {
                $outp = New-UserInputSuggestion 'asd' 'dsa'
                $outp.Value | Should -BeExactly 'asd'
                $outp.Display | Should -BeExactly 'dsa'
            }
        }

        Context 'Usage' {
            It 'uses the value when picking suggestion' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Tab, $VK_Return)

                $outp = Get-UserInput -Suggestions @(New-UserInputSuggestion 'asd' 'dsa')
                $outp | Should -BeExactly 'asd'
            }
        }
    }
}
