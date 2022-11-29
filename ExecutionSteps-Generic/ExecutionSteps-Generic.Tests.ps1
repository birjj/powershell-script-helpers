BeforeAll {
    Get-Module -Name ExecutionSteps-Generic | Remove-Module -Force
    Get-Module -Name ExecutionStep | Remove-Module -Force
    Import-Module $(Join-Path $PSScriptRoot ..\ExecutionSteps)
    Import-Module $(Join-Path $PSScriptRoot .\ExecutionSteps-Generic)
}

Describe 'New-PowerShellVersionCheck' {
    BeforeAll {
        $oldVersion = $PSVersionTable.PSVersion
    }
    AfterAll {
        $PSVersionTable.PSVersion = $oldVersion
    }
    
    It 'works with major versions' {
        $step = New-PowerShellVersionCheck -major 5 -minor 0 -patch 0
        $PSVersionTable.PSVersion = [System.Version]"4.9.9"
        { $step.Run() } | Should -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.0.0"
        { $step.Run() } | Should -Not -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.0.1"
        { $step.Run() } | Should -Not -Throw
        $PSVersionTable.PSVersion = [System.Version]"6.0.0"
        { $step.Run() } | Should -Not -Throw
    }

    It 'works with minor versions' {
        $step = New-PowerShellVersionCheck -major 5 -minor 5 -patch 0
        $PSVersionTable.PSVersion = [System.Version]"4.9.9"
        { $step.Run() } | Should -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.4.9"
        { $step.Run() } | Should -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.5.0"
        { $step.Run() } | Should -Not -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.5.1"
        { $step.Run() } | Should -Not -Throw
        $PSVersionTable.PSVersion = [System.Version]"6.0.0"
        { $step.Run() } | Should -Not -Throw
    }

    It 'works with patch versions' {
        $step = New-PowerShellVersionCheck -major 5 -minor 5 -patch 5
        $PSVersionTable.PSVersion = [System.Version]"4.9.9"
        { $step.Run() } | Should -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.4.9"
        { $step.Run() } | Should -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.5.4"
        { $step.Run() } | Should -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.5.5"
        { $step.Run() } | Should -Not -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.5.6"
        { $step.Run() } | Should -Not -Throw
        $PSVersionTable.PSVersion = [System.Version]"5.6.0"
        { $step.Run() } | Should -Not -Throw
        $PSVersionTable.PSVersion = [System.Version]"6.0.0"
        { $step.Run() } | Should -Not -Throw
    }
}

Describe 'New-GitUpdateCheck' {
    It 'should react if git is not installed' {
        Mock git {} -ModuleName 'ExecutionSteps-Generic'
        Mock Get-Command {
            return $null
        } -ParameterFilter { $Name -eq 'git' } -ModuleName 'ExecutionSteps-Generic'

        $step = New-GitUpdateCheck $PSBoundParameters
        { $step.Run() 3>$null } | Should -Not -Throw # should just exit early, but not throw
        $requiredStep = New-GitUpdateCheck $PSBoundParameters -required
        { $requiredStep.Run() } | Should -Throw # if required, should throw
        # make sure we didn't proceed to the point where we called a git command
        Should -Invoke git -Times 0 -ModuleName 'ExecutionSteps-Generic' # -Because "Shouldn't check Git tags if Git isn't installed"
    }

    It 'should react if not in a git repo' {
        Mock git {
            throw "Not in git repo"
        } -ParameterFilter { $args[0] -eq 'rev-parse' } -ModuleName 'ExecutionSteps-Generic'

        $step = New-GitUpdateCheck $PSBoundParameters
        { $step.Run() 3>$null } | Should -Not -Throw # should just exit early, but not throw
        $requiredStep = New-GitUpdateCheck $PSBoundParameters -required
        { $requiredStep.Run() } | Should -Throw # if required, should throw
        # make sure we didn't proceed to the point where we called a git command
        Should -Invoke git -Times 0 -ParameterFilter { $args[0] -eq 'describe' } -ModuleName 'ExecutionSteps-Generic' # -Because "Shouldn't check Git tags if Git isn't installed"
    }

    It 'should not ask for updates if versions match' {
        Mock git {
            return "In git repo"
        } -ParameterFilter { $args[0] -eq 'rev-parse' } -ModuleName 'ExecutionSteps-Generic'
        Mock git { # remote tag mock
            'From test`nabc        refs/tags/v1.0.1^{}'
        } -ParameterFilter { $args[0] -eq 'ls-remote' } -ModuleName 'ExecutionSteps-Generic'
        Mock git { # local tag mock
            'v1.0.0'
        } -ParameterFilter { $args[0] -eq 'describe' } -ModuleName 'ExecutionSteps-Generic'
        Mock Get-Host { # PromptForChoice mock
            [pscustomobject] @{
                UI = Add-Member -PassThru -Name PromptForChoice -InputObject ([pscustomobject] @{}) -Type ScriptMethod -Value { return 1 }
            }
        } -ModuleName 'ExecutionSteps-Generic'

        $step = New-GitUpdateCheck $PSBoundParameters
        $step.Run()
        Should -Invoke Get-Host -Times 0 -ModuleName 'ExecutionSteps-Generic'
    }

    It "should ask for updates if versions don't match" {
        Mock git {
            return "In git repo"
        } -ParameterFilter { $args[0] -eq 'rev-parse' } -ModuleName 'ExecutionSteps-Generic'
        Mock git { # remote tag mock
            'From test`nabc        refs/tags/v1.0.0^{}`ncba        refs/tags/v1.0.1^{}'
        } -ParameterFilter { $args[0] -eq 'ls-remote' } -ModuleName 'ExecutionSteps-Generic'
        Mock git { # local tag mock
            'v1.0.0'
        } -ParameterFilter { $args[0] -eq 'describe' } -ModuleName 'ExecutionSteps-Generic'
        Mock Get-Host { # PromptForChoice mock
            [pscustomobject] @{
                UI = Add-Member -PassThru -Name PromptForChoice -InputObject ([pscustomobject] @{}) -Type ScriptMethod -Value { return 1 }
            }
        } -ModuleName 'ExecutionSteps-Generic'

        $step = New-GitUpdateCheck $PSBoundParameters
        $step.Run()
        Should -Invoke Get-Host -Times 1 -ModuleName 'ExecutionSteps-Generic'
    }
}
