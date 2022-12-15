<#
.SYNOPSIS
    Creates a new ExecutionStep instance using the given name and execution script block (and optionally cleanup script blocks)

.DESCRIPTION
    Creates a new ExecutionStep. An ExecutionStep represents a single step of a script execution, and can be executed using Invoke-ExecutionSteps.
    An ExecutionStep consists of:
    - A "run" scriptblock, which will be executed when the step should do its thing
    - Optionally a "cleanup" scriptblock, which will be executed if a later step (or the step itself) throws an error
    - Optionally a "finally" scriptblock, which will be executed when script execution ends, regardless of whether it succeeded
    See Invoke-ExecutionSteps for more information

.EXAMPLE
    PS> $psVersionStep = New-ExecutionStep 'Check PowerShell version >= 7' {
        if ($PSVersionTable.PSVersion -lt 7) {
            throw "PowerShell 7 is required to run this script, current version is $($PSVersionTable.PSVersion)"
        }
    }
#>
function New-ExecutionStep {
    param(
        # The human-readable name that represents this step
        [Parameter(Mandatory = $true)] [string] $name,
        # The scriptblock that will be executed when the step should do its thing
        [Parameter(Mandatory = $true)] [scriptblock] $run,
        # An optional scriptblock which will be executed if a later step (or the step itself) throws an error
        [Parameter(Mandatory = $false)] [scriptblock] $cleanup,
        # An optional scriptblock which will be executed when script execution ends, regardless of whether it succeeded. Useful for cleaning up stuff that's needed by later steps.
        [Parameter(Mandatory = $false)] [scriptblock] $final
    )
    [ExecutionStep]::new(
        $name,
        $run,
        $cleanup,
        $final
    )
}
