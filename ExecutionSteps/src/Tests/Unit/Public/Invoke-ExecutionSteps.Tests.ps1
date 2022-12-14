Set-Location -Path $PSScriptRoot
$ModuleName = 'ExecutionSteps'
$PathToManifest = [System.IO.Path]::Combine('..', '..', '..', $ModuleName, "$ModuleName.psd1")
if (Get-Module -Name $ModuleName -ErrorAction 'SilentlyContinue') {
    #if the module is already in memory, remove it
    Remove-Module -Name $ModuleName -Force
}
Import-Module $PathToManifest -Force
#-------------------------------------------------------------------------

InModuleScope 'ExecutionSteps' {
    Describe 'Invoke-ExecutionSteps' -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        } #beforeAll

        BeforeEach {
            function runner() { "real" }
            Mock runner { "mock" }
            function cleaner() { "real" }
            Mock cleaner { "mock" }
            function finalizer() { "real" }
            Mock finalizer { "mock" }
        }

        Context 'Success' {
            It 'executes all steps' {
                $steps = @(
                    $(New-ExecutionStep 'test-1' { runner } $null { finalizer }),
                    $(New-ExecutionStep 'test-2' { runner } $null { finalizer }),
                    $(New-ExecutionStep 'test-3' { runner } $null { finalizer })
                )
                Invoke-ExecutionSteps $steps 6>&1
                Should -Invoke runner -Exactly 3
                Should -Invoke runner -Exactly 3
            }

            It 'writes to host if not silent' {
                $steps = @(
                    $(New-ExecutionStep 'test-1' { runner })
                )
                $outp = Invoke-ExecutionSteps $steps 6>&1 | Out-String
                $outp | Should -Match 'Running test-1'
            }

            It 'does not write to host if silent' {
                $steps = @(
                    $(New-ExecutionStep 'test-1' { runner })
                )
                $outp = Invoke-ExecutionSteps $steps -Silent 6>&1 | Out-String
                $outp | Should -Not -Match 'Running test-1'
            }
        } #context_Success

        Context 'Error' {
            It 'stops and cleans up if an error occurs' {
                $steps = @(
                    $(New-ExecutionStep 'test-1' { runner } { cleaner } { finalizer }),
                    $(New-ExecutionStep 'test-2' { runner } { cleaner } { finalizer }),
                    $(New-ExecutionStep 'test-3' { runner; throw 'Custom error' } { cleaner } { finalizer })
                    $(New-ExecutionStep 'test-4' { runner } { cleaner } { finalizer })
                )
                $thrown = $null
                try {
                    Invoke-ExecutionSteps $steps 6>&1
                } catch { $thrown = $_ }
                Should -Invoke runner -Exactly 3 # -Because 'the execution should stop when an error occurs'
                Should -Invoke cleaner -Exactly 3 # -Because 'all executed steps, including the failing one, should be cleaned up'
                Should -Invoke finalizer -Exactly 3 # -Because "all executed steps should have their finalizer ran, regardless of success"
                $thrown | Should -BeExactly 'Custom error'
            }

            It 'stops cleanup if another error occurs' {
                $steps = @(
                    $(New-ExecutionStep 'test-1' { runner } { cleaner } { finalizer }),
                    $(New-ExecutionStep 'test-2' { runner } { cleaner; throw 'Custom error #2' } { finalizer }),
                    $(New-ExecutionStep 'test-3' { runner; throw 'Custom error' } { cleaner } { finalizer })
                    $(New-ExecutionStep 'test-4' { runner } { cleaner } { finalizer })
                )
                $thrown = $null
                try {
                    Invoke-ExecutionSteps $steps 6>&1
                } catch { $thrown = $_ }
                Should -Invoke runner -Exactly 3 # -Because 'the execution should stop when an error occurs'
                Should -Invoke cleaner -Exactly 2 # -Because 'all executed steps, including the failing one, should be cleaned up'
                Should -Invoke finalizer -Exactly 3 # -Because "all executed steps should have their finalizer ran, regardless of success"
                $thrown | Should -BeExactly 'Custom error'
            }

            It 'stops finalization if another error occurs' {
                $steps = @(
                    $(New-ExecutionStep 'test-1' { runner } { cleaner } { finalizer }),
                    $(New-ExecutionStep 'test-2' { runner } { cleaner } { finalizer; throw 'Custom error #2' }),
                    $(New-ExecutionStep 'test-3' { runner; throw 'Custom error' } { cleaner } { finalizer })
                    $(New-ExecutionStep 'test-4' { runner } { cleaner } { finalizer })
                )
                $thrown = $null
                try {
                    Invoke-ExecutionSteps $steps 6>&1
                } catch { $thrown = $_ }
                Should -Invoke runner -Exactly 3 # -Because 'the execution should stop when an error occurs'
                Should -Invoke cleaner -Exactly 3 # -Because 'all executed steps, including the failing one, should be cleaned up'
                Should -Invoke finalizer -Exactly 2 # -Because "all executed steps should have their finalizer ran, regardless of success"
                $thrown | Should -BeExactly 'Custom error'
            }
        } #context_Error
    }
} #inModule
