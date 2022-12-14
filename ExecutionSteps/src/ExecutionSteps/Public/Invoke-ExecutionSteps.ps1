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

.EXAMPLE
    PS> Invoke-ExecutionSteps @(
        New-ExecutionStep 'Test 1' { Write-Host "Something's happening in test 1" }
        New-ExecutionStep 'Test 2' { Write-Host "And now in test 2!" }
        New-ExecutionStep 'Test 3' { Write-Host "And lastly in step 3." }
    )

    Running Test 1
    Something's happening in test 1
    Running Test 2
    And now in test 2!
    Running Test 3
    And lastly in step 3.
    Finalizing Test 3
    Finalizing Test 2
    Finalizing Test 1


    The script was successfully executed
#>
function Invoke-ExecutionSteps {
    param(
        # the list of steps to execute
        [Parameter(Mandatory = $true)] [ExecutionStep[]] $steps,
        # if set, don't write human-readable output to host
        [switch] $silent
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
        } catch {
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
                } catch {
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
        } catch {
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

    if ($status.Error) {
        throw $status.Error
    }

    return $null
}
