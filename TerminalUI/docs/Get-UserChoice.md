---
external help file: TerminalUI-help.xml
Module Name: TerminalUI
online version:
schema: 2.0.0
---

# Get-UserChoice

## SYNOPSIS
Prompts the user to choose one of multiple options.
Similar to $Host.UI.PromptForChoice, but with a different UI and more options.

## SYNTAX

```
Get-UserChoice [-Items] <Object[]> [-Multi] [-NoHelp] [<CommonParameters>]
```

## DESCRIPTION
Prompts the user to choose one of multiple options.
Similar to $Host.UI.PromptForChoice, but with a different UI and more options.

## EXAMPLES

### EXAMPLE 1
```
Get-UserChoice 'Foo','Bar','Baz'
$ User is shown a list of options ('Foo', 'Bar' and 'Baz'), of which they can pick one
$ Return value will be the one they choose
```

### EXAMPLE 2
```
Get-UserChoice 'Foo','Bar','Baz' -Multi
$ User is shown a list of options ('Foo', 'Bar' and 'Baz'), of which they can pick multiple
$ Return value will be a list of the ones they choose
```

## PARAMETERS

### -Items
A list of options the user can pick from.
The user will be shown these, and can choose one (or more, if -Multi is set).
Items can be a list of strings, or a list of \`\[UserChoiceItem\]\` if you want more control over how they are presented to the user.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Multi
If set, users can pick more than one option.
They must choose at least one.
The return value will change to a list of the chosen values (or an empty list, if the user cancels)

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

### -NoHelp
If set, don't show the user how to use the prompt (e.g.
'\[↑↓\] Move  \[Enter\] Submit  \[Esc\] Cancel').

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

### The value the user picked, or a list of values if -Multi is set.
### If the user cancels, `$null` will be returned (or `@()` if -Multi is set).
## NOTES

## RELATED LINKS
