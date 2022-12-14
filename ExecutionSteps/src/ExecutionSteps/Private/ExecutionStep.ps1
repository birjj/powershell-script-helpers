# Represents an execution step, which can be executed and potentially be cleaned up
class ExecutionStep {
    [string] $Name
    [object] $State
    [scriptblock] hidden $_Run
    [scriptblock] hidden $_Cleanup
    [scriptblock] hidden $_Final

    ExecutionStep([string] $Name, [scriptblock] $Run) {
        $this.Name = $Name
        $this._Run = $Run
        $this._Cleanup = $null
        $this._Final = $null
    }
    ExecutionStep([string] $Name, [scriptblock] $Run, [scriptblock] $Cleanup) {
        $this.Name = $Name
        $this._Run = $Run
        $this._Cleanup = $Cleanup
        $this._Final = $null
    }
    ExecutionStep([string] $Name, [scriptblock] $Run, [scriptblock] $Cleanup, [scriptblock] $Final) {
        $this.Name = $Name
        $this._Run = $Run
        $this._Cleanup = $Cleanup
        $this._Final = $Final
    }

    [object] Run() {
        return (& $this._Run)
    }

    [object] Cleanup() {
        if ($null -eq $this._Cleanup) {
            return $null
        }
        return (& $this._Cleanup)
    }

    [object] Final() {
        if ($null -eq $this._Final) {
            return $null
        }
        return (& $this._Final)
    }
}

