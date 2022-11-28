# check if PS version is at least the given one
function New-PowerShellVersionCheck {
    param(
        [Parameter(Mandatory = $true)][int] $major,
        [Parameter(Mandatory = $false)][int] $minor = 0,
        [Parameter(Mandatory = $false)][int] $patch = 0,
        [Parameter(Mandatory = $false)][string] $help
    )

    $version = [System.Version]"$major.$minor.$patch"
    $test = {
        Write-Host -ForegroundColor Green "Testing $version <= $($PSVersionTable.PSVersion)"
        if ($PSVersionTable.PSVersion -lt $version) {
            $msg = "PowerShell $version is required to run this script, current version is $($PSVersionTable.PSVersion)"
            if ($help) {
                $msg += "`n$help"
            }
            throw $msg
        }
    }.GetNewClosure()
    
    return New-ExecutionStep "PowerShell version >= $version check" $test
}

Export-ModuleMember -Function New-PowerShellVersionCheck