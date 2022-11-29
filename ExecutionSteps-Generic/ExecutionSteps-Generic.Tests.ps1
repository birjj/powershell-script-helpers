BeforeAll {
    Get-Module -Name ExecutionSteps-Generic | Remove-Module -Force
    Get-Module -Name ExecutionStep | Remove-Module -Force
    Import-Module $(Join-Path $PSScriptRoot ..\ExecutionStep)
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