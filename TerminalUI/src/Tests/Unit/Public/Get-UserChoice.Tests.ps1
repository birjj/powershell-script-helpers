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

    Describe 'Get-UserChoice' -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        } #beforeAll

        Context 'Output' {
            It 'returns the chosen value without $Multi' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Return)

                $outp = Get-UserChoice @('asd', 'dsa')
                $outp | Should -BeExactly 'asd'
            }

            It 'returns $null if cancelled without $Multi' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Esc)

                $outp = Get-UserChoice @('asd', 'dsa')
                $outp | Should -BeExactly $null
            }

            It 'returns a list of chosen values with $Multi' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Space, $VK_Down, $VK_Down, $VK_Space, $VK_Return)

                $outp = Get-UserChoice -Multi @('Foo', 'Bar', 'Baz', 'Qux', 'Quux')
                $outp | Should -BeExactly @('Foo', 'Baz')
            }

            It 'returns an empty list if cancelled with $Multi' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Esc)

                $outp = Get-UserChoice -Multi @('Foo', 'Bar', 'Baz', 'Qux', 'Quux')
                $outp | Should -BeExactly @()
            }
        }
    }

    Describe 'New-UserChoiceItem' -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        } #beforeAll

        Context 'Output' {
            It 'accepts a single value' {
                $outp = New-UserChoiceItem 'asd'
                $outp.Value | Should -BeExactly 'asd'
                $outp.Display | Should -BeExactly 'asd'
            }

            It 'accepts two values' {
                $outp = New-UserChoiceItem 'asd' 'dsa'
                $outp.Value | Should -BeExactly 'asd'
                $outp.Display | Should -BeExactly 'dsa'
            }
        }

        Context 'Usage' {
            It 'uses the value when picking suggestion' {
                # Replace the internal hook/variable to mock the ReadKey call
                Mock-ReadKey @($VK_Return)

                $outp = Get-UserChoice @(New-UserChoiceItem 'asd' 'dsa')
                $outp | Should -BeExactly 'asd'
            }
        }
    }
}
