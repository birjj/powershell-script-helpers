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

function Get-RemoteGitTag {
    $remoteTag = [string](git ls-remote --tags 2>$null | Select-Object -Last 1) -replace ".*/(.*)\^{}", "`$1"
    if ([string]::IsNullOrWhiteSpace($remoteTag)) { $remoteTag = '[none]' }
    return $remoteTag
}
function Get-LocalGitTag {
    $localTag = git describe --tags --abbrev=0 2>$null
    if ([string]::IsNullOrWhiteSpace($localTag)) { $localTag = '[none]' }
    return $localTag
}
function Test-IsInGitRepo {
    try {
        git rev-parse --git-dir 2> $null > $null
        return $?
    }
    catch {
        return $false
    }
}
function Test-GitPresence {
    $git = Get-Command "git" -ErrorAction Ignore
    return [bool]$git
}
function Prompt-ForChoice {
    param(
        [string]$caption,
        [string]$message,
        [string[]]$choices,
        [int]$default
    )
    return (Get-Host).UI.PromptForChoice($caption, $message, $choices, $default)
}

# checks if the current git repo has a new tag on the remote
function New-GitUpdateCheck {
    param(
        [Parameter(Mandatory = $true)][object] $scriptParams, # should be $PSBoundParameters from the script, used to re-run script
        [switch] $required # if present, throw an error if we aren't in a git repo - otherwise ignore it silently
    )

    $SCRIPT_PATH = $MyInvocation.PSCommandPath
    $SCRIPT_PARAMS = $scriptParams

    # this is a bit of a hacky workaround for pester/Pester#2115
    # we need to move functions to global scope so they can be mocked
    # and then create references here so they're referenced inside .GetNewClosure()
    $getRemoteGitTag = ${Function:Get-RemoteGitTag}
    $getLocalGitTag = ${Function:Get-LocalGitTag}
    $testGitPresence = ${Function:Test-GitPresence}
    $testIsInGit = ${Function:Test-IsInGitRepo}
    $promptForChoice = ${Function:Prompt-ForChoice}

    $test = {
        $SCRIPT_PATH | Split-Path | Push-Location # make sure we execute commands from the scripts directory
        try {
            # check if git is even installed
            if (-Not (Invoke-Command $testGitPresence)) {
                $msg = "Git is required for script self-updating, but was not found."
                if ($required.IsPresent) {
                    throw $msg
                }
                else {
                    Write-Warning "$msg Self-updating will be skipped"
                    return
                }
            }
            # check if we're in a git repo
            if (-Not (Invoke-Command $testIsInGit)) {
                $msg = "Must be in a Git repository to self-update."
                if ($required.IsPresent) {
                    throw $msg
                }
                else {
                    Write-Warning "$msg Self-updating will be skipped"
                    return
                }
            }
            # check if there are new tags on remote
            $remoteTag = Invoke-Command $getRemoteGitTag
            $localTag = Invoke-Command $getLocalGitTag

            if ($localTag -ne $remoteTag) {
                $shouldUpdate = Invoke-Command $promptForChoice -ArgumentList @(
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
