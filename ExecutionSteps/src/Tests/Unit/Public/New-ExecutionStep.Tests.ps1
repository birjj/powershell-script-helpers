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
    Describe 'New-ExecutionStep' -Tag Unit {
        BeforeAll {
            $WarningPreference = 'SilentlyContinue'
            $ErrorActionPreference = 'SilentlyContinue'
        } #beforeAll

        Context 'Error' {
        } #context_Error

        Context 'Success' {
            It 'works with a single parameter' {
                $run_block = { 'Testing' }
                $step = New-ExecutionStep 'test' $run_block
                $step.Run() | Should -BeExactly (& $run_block)
                $step.Cleanup() | Should -BeExactly $null
                $step.Final() | Should -BeExactly $null
            }

            It 'works with two parameters' {
                $run_block = { "Test run" }
                $cleanup_block = { "Test cleanup" }
                $step = New-ExecutionStep 'test' $run_block $cleanup_block
                $step.Run() | Should -BeExactly (& $run_block)
                $step.Cleanup() | Should -BeExactly (& $cleanup_block)
                $step.Final() | Should -BeExactly $null
            }

            It 'works with three parameters' {
                $run_block = { "Test run" }
                $cleanup_block = { "Test cleanup" }
                $final_block = { "Test finally" }
                $step = New-ExecutionStep 'test' $run_block $cleanup_block $final_block
                $step.Run() | Should -BeExactly (& $run_block)
                $step.Cleanup() | Should -BeExactly (& $cleanup_block)
                $step.Final() | Should -BeExactly (& $final_block)
            }
        } #context_Success
    } #describe_Get-HellowWorld
} #inModule
