# Bootstrap dependencies
# This file was generated by Catesta https://github.com/techthoughts2/Catesta

$esc = [char]27
"${esc}[90mAdding package provider NuGet${esc}[0m"
Get-PackageProvider -Name Nuget -ForceBootstrap | Out-Null
"${esc}[90mSetting up PSGallery${esc}[0m"
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# List of PowerShell Modules required for the build
$modulesToInstall = [System.Collections.ArrayList]::new()
# https://github.com/pester/Pester
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'Pester'
            ModuleVersion = '5.3.3'
        }))
# https://github.com/nightroman/Invoke-Build
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'InvokeBuild'
            ModuleVersion = '5.10.1'
        }))
# https://github.com/PowerShell/PSScriptAnalyzer
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'PSScriptAnalyzer'
            ModuleVersion = '1.21.0'
        }))
# https://github.com/PowerShell/platyPS
# older version used due to: https://github.com/PowerShell/platyPS/issues/457
$null = $modulesToInstall.Add(([PSCustomObject]@{
            ModuleName    = 'platyPS'
            ModuleVersion = '0.12.0'
        }))



"${esc}[90mInstalling PowerShell modules${esc}[0m"
foreach ($module in $modulesToInstall) {
    $installSplat = @{
        Name               = $module.ModuleName
        RequiredVersion    = $module.ModuleVersion
        Repository         = 'PSGallery'
        SkipPublisherCheck = $true
        Force              = $true
        ErrorAction        = 'Stop'
    }
    $curVersion = Get-Module $module.ModuleName | Select-Object -ExpandProperty Version
    if ($curVersion -eq $module.ModuleVersion) {
        "${esc}[90m  - Already installed $($module.ModuleName) ${curVersion}, skipping${esc}[0m"
        continue
    }

    try {
        "  - Installing $($module.ModuleName) $($module.ModuleVersion) (from old version ${curVersion})"
        Install-Module @installSplat
        Import-Module -Name $module.ModuleName -ErrorAction Stop
        $newVersion = Get-Module $module.ModuleName | Select-Object -ExpandProperty Version
        if ($newVersion -ne $module.ModuleVersion) {
            throw "New version ${newVersion} does not match expected $($module.ModuleVersion)"
        }
        "${esc}[32m  - Successfully installed $($module.ModuleName) ${newVersion}${esc}[0m"
    }
    catch {
        $message = "Failed to install $($module.ModuleName) $($module.ModuleVersion)"
        "${esc}[31m  - $message${esc}[0m"
        throw
    }
}

