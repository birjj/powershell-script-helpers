---
external help file: ExecutionSteps-help.xml
Module Name: ExecutionSteps
online version:
schema: 2.0.0
---

# Invoke-ExecutionSteps

## SYNOPSIS
Executes a list of ExecutionSteps, outputting human-readable progress (unless asked to be silent)

## SYNTAX

```
Invoke-ExecutionSteps [-steps] <ExecutionStep[]> [-silent] [<CommonParameters>]
```

## DESCRIPTION
Executes a list of ExecutionSteps.
The "run" scriptblock of each ExecutionStep will be executed in order until one of them throws an error, or there are no more ExecutionSteps.

If an ExecutionStep throws an error, no further steps will be executed, and cleanup will instead commence.
This happens by executing the "cleanup" scriptblock of each step, in reverse order, starting from the step that threw an error.
If an error should occur during the cleanup stage, cleanup will end prematurely.
Otherwise it will continue until all executed steps have been cleaned up.

Regardless of whether an error occured or not, the "finally" scriptblock of each executed step will be ran once every other stage is done.
This will happen in reverse order, just like "cleanup", and offers each step the opportunity to clean up any resources that should be removed even if execution succeeds.

## EXAMPLES

### EXAMPLE 1
```
Invoke-ExecutionSteps @(
    New-ExecutionStep 'Test 1' { Write-Host "Something's happening in test 1" }
    New-ExecutionStep 'Test 2' { Write-Host "And now in test 2!" }
    New-ExecutionStep 'Test 3' { Write-Host "And lastly in step 3." }
)
```

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

## PARAMETERS

### -steps
the list of steps to execute

```yaml
Type: ExecutionStep[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -silent
if set, don't write human-readable output to host

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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
