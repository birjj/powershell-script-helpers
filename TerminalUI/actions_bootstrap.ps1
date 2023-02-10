# Bootstrap dependencies

# https://docs.microsoft.com/powershell/module/packagemanagement/get-packageprovider
Get-PackageProvider -Name Nuget -ForceBootstrap | Out-Null

# https://docs.microsoft.com/powershell/module/powershellget/set-psrepository
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



'Installing PowerShell Modules'
foreach ($module in $modulesToInstall) {
    $updateSplat = @{
        Name            = $module.ModuleName
        RequiredVersion = $module.ModuleVersion
        Force           = $true
        ErrorAction     = 'Stop'
    }
    $installSplat = @{
        Name               = $module.ModuleName
        RequiredVersion    = $module.ModuleVersion
        Repository         = 'PSGallery'
        SkipPublisherCheck = $true
        Force              = $true
        ErrorAction        = 'Stop'
    }
    $curVersion = Get-Module $module.ModuleName | Select-Object -ExpandProperty Version -Last 1
    if ($curVersion -eq $module.ModuleVersion) {
        "  - Already installed $($module.ModuleName) ${curVersion}, skipping"
        continue
    }
    try {
        if ($curVersion) {
            "  - Updating to $($module.ModuleName) $($module.ModuleVersion) (from old version ${curVersion})"
            Update-Module @updateSplat
        } else {
            "  - Installing $($module.ModuleName) $($module.ModuleVersion) (not previously installed)"
            Install-Module @installSplat
        }
        Import-Module -Name $module.ModuleName -RequiredVersion $module.ModuleVersion -ErrorAction Stop
        $newVersion = Get-Module $module.ModuleName | Select-Object -ExpandProperty Version -Last 1
        if ($newVersion -ne $module.ModuleVersion) {
            throw "New version ${newVersion} does not match expected $($module.ModuleVersion)"
        }
        '  - Successfully installed {0}' -f $module.ModuleName
    } catch {
        $message = 'Failed to install {0}' -f $module.ModuleName
        "  - $message"
        throw
    }
}

