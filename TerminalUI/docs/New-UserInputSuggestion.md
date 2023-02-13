---
external help file: TerminalUI-help.xml
Module Name: TerminalUI
online version:
schema: 2.0.0
---

# New-UserInputSuggestion

## SYNOPSIS
Creates a new suggestion for use with Get-UserInput.
Should only be used if you need to display something other than the value the suggestion represents.

## SYNTAX

```
New-UserInputSuggestion [-Value] <String> [[-Display] <String>] [<CommonParameters>]
```

## DESCRIPTION
Creates a new suggestion for use with Get-UserInput.
Normally you'd simply pass a string to Get-UserInput, but in some cases you want to display something other than the suggestion value.
In those cases you can create a suggestion using New-UserInputSuggestion that has a display string and a value.

## EXAMPLES

### EXAMPLE 1
```
Get-UserInput -Suggestions @(New-UserInputSuggestion 'Foo')
$ Will display the suggestion as 'Foo', when chosen will enter 'Foo'
```

### EXAMPLE 2
```
Get-UserInput -Suggestions @(New-UserInputSuggestion -Value 'Foo' -Display 'Metasyntactic variable')
$ Will display the suggestion as 'Metasyntactic variable', when chosen will enter 'Foo'
```

### EXAMPLE 3
```
Get-UserInput -Suggestions @(New-UserInputSuggestion 'Foo' 'Metasyntactic variable')
$ Will display the suggestion as 'Metasyntactic variable', when chosen will enter 'Foo'
```

## PARAMETERS

### -Value
The value to enter when the suggestion is chosen.

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

### -Display
The string to display in the suggestions list.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $Value
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### An instance of the internal `[UserInputSuggestion]` class.
## NOTES

## RELATED LINKS
