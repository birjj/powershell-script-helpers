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

# checks if the current git repo has a new tag on the remote
function New-GitUpdateCheck {
    param(
        [Parameter(Mandatory = $true)][object] $scriptParams, # should be $PSBoundParameters from the script, used to re-run script
        [switch] $required # if present, throw an error if we aren't in a git repo - otherwise ignore it silently
    )

    $SCRIPT_PATH = $MyInvocation.PSCommandPath
    $SCRIPT_PARAMS = $scriptParams

    Write-Host -ForegroundColor Blue "Running in $SCRIPT_PATH with $SCRIPT_PARAMS"
    Write-Host -ForegroundColor Blue $($SCRIPT_PARAMS | ConvertTo-Json)

    $test = {
        $SCRIPT_PATH | Split-Path | Push-Location # make sure we execute commands from the scripts directory
        try {
            # check if git is even installed
            if (-Not (Get-Command "git" -ErrorAction Ignore)) {
                if ($required.IsPresent) {
                    throw "Git is required for script self-updating, but was not found."
                    return
                }
                else {
                    Write-Warning "Git is required for script self-updating, but was not found. Self-updating will be skipped"
                    return
                }
            }

            # check if we're in a git repo
            git rev-parse --git-dir 2> $null > $null
            $isInGit = $?
            if (-Not $isInGit) {
                if ($required.IsPresent) {
                    throw "Must be in a Git repository to self-update."
                }
                else {
                    Write-Warning "Must be in a Git repository to self-update. Self-updating will be skipped"
                    return
                }
            }

            # check if there are new tags on remote
            $remoteTag = [string](git ls-remote --tags 2>$null | Select-Object -Last 1) -replace ".*/(.*)\^{}", "`$1"
            if ([string]::IsNullOrWhiteSpace($removeTag)) { $remoteTag = '[none]' }
            $localTag = git describe --tags --abbrev=0 2>$null
            if ([string]::IsNullOrWhiteSpace($localTag)) { $localTag = '[none]' }

            Write-Host -ForegroundColor Green "Comparing local $localTag to remote $remoteTag."

            if ($localTag -ne $remoteTag) {
                $shouldUpdate = $host.UI.PromptForChoice(
                    "Should script be updated?",
                    "A new version $remoteTag of this script exists (local version is $localTag). Do you want to do a git pull now?`nThis will overwrite any uncommitted local changes you have.",
                    @("&Yes, update script", "&No, use current version"),
                    0
                )
                if ($shouldUpdate -eq 0) {
                    git checkout -f master | Out-Host
                    git pull | Out-Host
                    $success = $?
                    if ($success) {
                        & $SCRIPT_PATH @SCRIPT_PARAMS | Out-Host # rerun self
                        Exit
                    }
                    else {
                        throw "Failed to update script"
                    }
                }
            }
        }
        finally {
            Pop-Location # make sure we return to the old execution location
        }
    }.GetNewClosure()

    return New-ExecutionStep "Git update check" $test
}

Export-ModuleMember -Function New-PowerShellVersionCheck, New-GitUpdateCheck