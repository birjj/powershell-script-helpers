BeforeAll {
    Get-Module -Name ExecutionSteps | Remove-Module -Force
    Import-Module $(Join-Path $PSScriptRoot .\ExecutionSteps)
}

Describe 'New-ExecutionStep' {
    It 'works with a single parameter' {
        $run_block = { "Testing" }
        $step = New-ExecutionStep 'test' $run_block
        $step._Run | Should -Be $run_block
        $step._Cleanup | Should -BeNullOrEmpty
        $step._Finally | Should -BeNullOrEmpty
    }

    It 'works with two parameters' {
        $run_block = { "Test run" }
        $cleanup_block = { "Test cleanup" }
        $step = New-ExecutionStep 'test' $run_block $cleanup_block
        $step._Run | Should -Be $run_block
        $step._Cleanup | Should -Be $cleanup_block
        $step._Finally | Should -BeNullOrEmpty
    }

    It 'works with three parameters' {
        $run_block = { "Test run" }
        $cleanup_block = { "Test cleanup" }
        $finally_block = { "Test finally" }
        $step = New-ExecutionStep 'test' $run_block $cleanup_block $finally_block
        $step._Run | Should -Be $run_block
        $step._Cleanup | Should -Be $cleanup_block
        $step._Finally | Should -Be $finally_block
    }
}

Describe 'Invoke-ExecutionSteps' {
    BeforeAll {
        function runner() { "real" }
        Mock runner { "mock" }
        function cleaner() { "real" }
        Mock cleaner { "mock" }
        function finalizer() { "real" }
        Mock finalizer { "mock" }
    }
    It 'executes all steps' {
        $steps = @(
            $(New-ExecutionStep 'test-1' { runner } $null { finalizer }),
            $(New-ExecutionStep 'test-2' { runner } $null { finalizer }),
            $(New-ExecutionStep 'test-3' { runner } $null { finalizer })
        )
        $outp = Invoke-ExecutionSteps $steps -Silent
        Should -Invoke runner -Exactly 3
        Should -Invoke runner -Exactly 3
        $outp.Succeeded.Count | Should -Be 3
    }
    It 'stops and cleans up if an error occurs' {
        $steps = @(
            $(New-ExecutionStep 'test-1' { runner } { cleaner } { finalizer }),
            $(New-ExecutionStep 'test-2' { runner } { cleaner } { finalizer }),
            $(New-ExecutionStep 'test-3' { runner; throw 'Custom error' } { cleaner } { finalizer })
            $(New-ExecutionStep 'test-4' { runner } { cleaner } { finalizer })
        )
        $outp = Invoke-ExecutionSteps $steps -Silent
        Should -Invoke runner -Exactly 3 # -Because 'the execution should stop when an error occurs'
        Should -Invoke cleaner -Exactly 3 # -Because 'all executed steps, including the failing one, should be cleaned up'
        Should -Invoke finalizer -Exactly 3 # -Because "all executed steps should have their finalizer ran, regardless of success"
        $outp.Succeeded.Count | Should -Be 2 # -Because 'the output should contain the correct succeeded steps'
        $outp.Error | Should -Be 'Custom error' # -Because 'the output should contain the correct error'
        $outp.Errored | Should -Be $steps[2] # -Because 'the output should contain the correct errored step'
    }
}
