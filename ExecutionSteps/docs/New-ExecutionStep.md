---
external help file: ExecutionSteps-help.xml
Module Name: ExecutionSteps
online version:
schema: 2.0.0
---

# New-ExecutionStep

## SYNOPSIS
Creates a new ExecutionStep instance using the given name and execution script block (and optionally cleanup script blocks)

## SYNTAX

```
New-ExecutionStep [-name] <String> [-run] <ScriptBlock> [[-cleanup] <ScriptBlock>] [[-final] <ScriptBlock>]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a new ExecutionStep.
An ExecutionStep represents a single step of a script execution, and can be executed using Invoke-ExecutionSteps.
An ExecutionStep consists of:
- A "run" scriptblock, which will be executed when the step should do its thing
- Optionally a "cleanup" scriptblock, which will be executed if a later step (or the step itself) throws an error
- Optionally a "finally" scriptblock, which will be executed when script execution ends, regardless of whether it succeeded
See Invoke-ExecutionSteps for more information

## EXAMPLES

### EXAMPLE 1
```
$psVersionStep = New-ExecutionStep 'Check PowerShell version >= 7' {
    if ($PSVersionTable.PSVersion -lt 7) {
        throw "PowerShell 7 is required to run this script, current version is $($PSVersionTable.PSVersion)"
    }
}
```

## PARAMETERS

### -name
The human-readable name that represents this step

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -run
The scriptblock that will be executed when the step should do its thing

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -cleanup
An optional scriptblock which will be executed if a later step (or the step itself) throws an error

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -final
An optional scriptblock which will be executed when script execution ends, regardless of whether it succeeded.
Useful for cleaning up stuff that's needed by later steps.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
