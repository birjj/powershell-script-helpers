function New-ExecutionStep {
    param(
        [Parameter(Mandatory = $true)] [string] $name,
        [Parameter(Mandatory = $true)] [scriptblock] $run,
        [Parameter(Mandatory = $false)] [scriptblock] $cleanup,
        [Parameter(Mandatory = $false)] [scriptblock] $finally
    )
    [ExecutionStep]::new(
        $name,
        $run,
        $cleanup,
        $finally
    )
}
function Invoke-ExecutionSteps {
    param(
        [Parameter(Mandatory = $true)] [ExecutionStep[]] $steps
    )

    $status = @{
        Succeeded = New-Object 'System.Collections.Generic.List[System.Object]'
        Errored   = $null
        Error     = $null
    }

    for ($i = 0; $i -lt $steps.Count; ++$i) {
        $step = $steps[$i]
        try {
            $step.Run()
            $status.Succeeded.Add($step)
        }
        catch {
            $err = $_
            $status.Errored = $step
            $status.Error = $err
            Write-Host -ForegroundColor Red "An error occured during $($step.Name), aborting execution"
            # try to undo every previous step
            for ($j = $i; $j -ge 0; --$j) {
                $prevStep = $steps[$j]
                try {
                    $prevStep.Cleanup()
                }
                catch {
                    Write-Error "${_}"
                    Write-Host -ForegroundColor Red "!!! An error occured during cleanup of $($prevStep.Name). Manual cleanup may be needed. !!!"
                    break
                }
            }
            # then summarize the result
            Write-Host
            Write-Host 
            Write-Host -ForegroundColor Red $err
            break
        }
    }

    for ($j = $i; $j -ge 0; --$j) {
        $prevStep = $steps[$j]
        if (-Not $prevStep) { continue }
        try {
            $prevStep.Finally()
        }
        catch {
            Write-Error "${_}"
            Write-Host -ForegroundColor Red "!!! An error occured during finalization of $($prevStep.Name). Manual cleanup may be needed. !!!"
            break
        }
    }
    
    if (-Not $status.Error) {
        Write-Host
        Write-Host
        Write-Host -ForegroundColor Green "The script was successfully executed"
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
        Write-Host -ForegroundColor DarkGray "Running $($this.Name)"
        Invoke-Command -ScriptBlock $this._Run
    }

    [void] Cleanup() {
        if ($null -eq $this._Cleanup) {
            return
        }
        Write-Host -ForegroundColor DarkGray "Cleaning up $($this.Name)"
        Invoke-Command -ScriptBlock $this._Cleanup
    }

    [void] Finally() {
        if ($null -eq $this._Finally) {
            return
        }
        Write-Host -ForegroundColor DarkGray "Finalizing $($this.Name)"
        Invoke-Command -ScriptBlock $this._Finally
    }
}

Export-ModuleMember -Function New-ExecutionStep
Export-ModuleMember -Function Invoke-ExecutionSteps
