---
external help file: TerminalUI-help.xml
Module Name: TerminalUI
online version:
schema: 2.0.0
---

# New-UserChoiceItem

## SYNOPSIS
Creates a new item for use with Get-UserChoice.
Should only be used if you need to display something other than the value the item represents.

## SYNTAX

```
New-UserChoiceItem [-Value] <Object> [[-Display] <String>] [<CommonParameters>]
```

## DESCRIPTION
Creates a new item for use with Get-UserChoice.
Normally you'd simply pass a string to Get-UserChoice, but in some cases you want to display something other than the item value.
In those cases you can create an item using New-UserChoiceItem that has a display string and a value.

## EXAMPLES

### EXAMPLE 1
```
Get-UserChoice @(New-UserChoiceItem 'Foo')
# will display the item as 'Foo', when chosen will return 'Foo'
```

### EXAMPLE 2
```
Get-UserChoice @(New-UserChoiceItem -Value 'Foo' -Display 'Metasyntactic variable')
# will display the item as 'Metasyntactic variable', when chosen will enter 'Foo'
```

### EXAMPLE 3
```
Get-UserInput @(New-UserChoiceItem 'Foo' 'Metasyntactic variable')
# will display the item as 'Metasyntactic variable', when chosen will enter 'Foo'
```

## PARAMETERS

### -Value
The value to return when the item is chosen.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Display
The string to display in the item list.

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

### An instance of the internal `[UserChoiceItem]` class.
## NOTES

## RELATED LINKS
