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
        # will stop execution of the script if the PowerShell version is < 7
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
        # An optional scriptblock which will be executed when script execution ends, regardless of whether it succeeded
        [Parameter(Mandatory = $false)] [scriptblock] $finally
    )
    [ExecutionStep]::new(
        $name,
        $run,
        $cleanup,
        $finally
    )
}

<#
.SYNOPSIS
    Executes a list of ExecutionSteps, outputting human-readable progress (unless asked to be silent)

.DESCRIPTION
    Executes a list of ExecutionSteps.
    The "run" scriptblock of each ExecutionStep will be executed in order until one of them throws an error, or there are no more ExecutionSteps.

    If an ExecutionStep throws an error, no further steps will be executed, and cleanup will instead commence.
    This happens by executing the "cleanup" scriptblock of each step, in reverse order, starting from the step that threw an error.
    If an error should occur during the cleanup stage, cleanup will end prematurely. Otherwise it will continue until all executed steps have been cleaned up.

    Regardless of whether an error occured or not, the "finally" scriptblock of each executed step will be ran once every other stage is done.
    This will happen in reverse order, just like "cleanup", and offers each step the opportunity to clean up any resources that should be removed even if execution succeeds.

.OUTPUTS
    System.Collections.Hashtable. Invoke-ExecutionSteps returns a hashtable indicating the final state of the execution.
    This is of the format:
    ```powershell
    @{
        Succeeded = @(...)  # list of all steps that succeeded
        Errored = $null     # or the ExecutionStep that failed, if an error was thrown
        Error = $null       # or the value that was thrown if an ExecutionStep failed
    }
    ```
#>
function Invoke-ExecutionSteps {
    param(
        [Parameter(Mandatory = $true)] [ExecutionStep[]] $steps,
        [switch] $silent,
        [switch] $resilient
    )

    $status = @{
        Succeeded = New-Object 'System.Collections.Generic.List[System.Object]'
        Errored   = $null
        Error     = $null
    }

    for ($i = 0; $i -lt $steps.Count; ++$i) {
        $step = $steps[$i]
        try {
            if (-Not $silent.IsPresent) {
                Write-Host -ForegroundColor DarkGray "Running $($step.Name)"
            }
            $step.Run()
            $status.Succeeded.Add($step)
        }
        catch {
            $err = $_
            $status.Errored = $step
            $status.Error = $err
            if (-Not $silent.IsPresent) {
                Write-Host -ForegroundColor Red "An error occured during $($step.Name), aborting execution"
            }
            # try to undo every previous step
            for ($j = $i; $j -ge 0; --$j) {
                $prevStep = $steps[$j]
                try {
                    if (-Not $silent.IsPresent) {
                        Write-Host -ForegroundColor DarkGray "Cleaning up $($prevStep.Name)"
                    }
                    $prevStep.Cleanup()
                }
                catch {
                    Write-Error "${_}"
                    if (-Not $silent.IsPresent) {
                        Write-Host -ForegroundColor Red "!!! An error occured during cleanup of $($prevStep.Name). Manual cleanup may be needed. !!!"
                    }
                    break
                }
            }
            # then summarize the result
            if (-Not $silent.IsPresent) {
                Write-Host
                Write-Host 
                Write-Host -ForegroundColor Red $err
            }
            break
        }
    }

    for ($j = $i; $j -ge 0; --$j) {
        $prevStep = $steps[$j]
        if (-Not $prevStep) { continue }
        try {
            if (-Not $silent.IsPresent) {
                Write-Host -ForegroundColor DarkGray "Finalizing $($prevStep.Name)"
            }
            $prevStep.Final()
        }
        catch {
            Write-Error "${_}"
            if (-Not $silent.IsPresent) {
                Write-Host -ForegroundColor Red "!!! An error occured during finalization of $($prevStep.Name). Manual cleanup may be needed. !!!"
            }
            break
        }
    }
    
    if (-Not $status.Error -and -Not $silent.IsPresent) {
        Write-Host
        Write-Host
        Write-Host -ForegroundColor Green "The script was successfully executed"
    }

    if ($status.Error -and -Not $resilient) {
        throw $status.Error
    }

    return $status
}

# Represents an execution step, which can be executed and potentially be cleaned up
class ExecutionStep {
    [string] $Name
    [object] $State
    [scriptblock] hidden $_Run
    [scriptblock] hidden $_Cleanup
    [scriptblock] hidden $_Finally

    ExecutionStep([string] $Name, [scriptblock] $Run) {
        $this.Name = $Name
        $this._Run = $Run
        $this._Cleanup = $null
        $this._Finally = $null
    }
    ExecutionStep([string] $Name, [scriptblock] $Run, [scriptblock] $Cleanup) {
        $this.Name = $Name
        $this._Run = $Run
        $this._Cleanup = $Cleanup
        $this._Finally = $null
    }
    ExecutionStep([string] $Name, [scriptblock] $Run, [scriptblock] $Cleanup, [scriptblock] $Finally) {
        $this.Name = $Name
        $this._Run = $Run
        $this._Cleanup = $Cleanup
        $this._Finally = $Finally
    }

    Run() {
        & $this._Run
    }

    [void] Cleanup() {
        if ($null -eq $this._Cleanup) {
            return
        }
        & $this._Cleanup
    }

    [void] Final() {
        if ($null -eq $this._Finally) {
            return
        }
        & $this._Final
    }
}

Export-ModuleMember -Function New-ExecutionStep, Invoke-ExecutionSteps
