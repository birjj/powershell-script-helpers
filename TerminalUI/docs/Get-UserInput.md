---
external help file: TerminalUI-help.xml
Module Name: TerminalUI
online version:
schema: 2.0.0
---

# Get-UserInput

## SYNOPSIS
Prompts the user for text input.
Similar to Read-Host, but with suggestions support.

## SYNTAX

```
Get-UserInput [[-Prompt] <String>] [[-Suggestions] <Object[]>] [[-MaxSuggestions] <Int32>] [-NoHelp]
 [-MaskInput]
```

## DESCRIPTION
Prompts the user for text input on the CLI.
Supports all parameters from the built-in Read-Host (except -AsSecureString), as well as suggestions.

## EXAMPLES

### EXAMPLE 1
```
Get-UserInput
# user is shown an empty line. Whatever they write will be returned after they press enter
```

### EXAMPLE 2
```
Get-UserInput -Prompt 'Test'
# user is shown a line containing 'Test: '. Whatever they write will be returned after they press enter
```

### EXAMPLE 3
```
Get-UserInput -Prompt 'Password' -MaskInput
# Whatever the user writes will be shown as a list of '*'. The returned value will be what the user entered
```

### EXAMPLE 4
```
Get-UserInput -Prompt 'Choose a color' -Suggestions 'Blue','Red','Green'
# The user is free to write whatever they want, but will be shown suggestions as they type
```

## PARAMETERS

### -Prompt
An optional text for the prompt.
The function appends a colon (\`:\`) to the text you enter, and displays it in bold to differentiate it from the users input.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Suggestions
A list of strings to use as suggestions to the user.
The user will be shown these, and can autocomplete them, but is also free to enter their own values.
Suggestions can be a list of strings, or a list of \`\[UserInputSuggestion\]\` if you want more control over how they are presented to the user.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxSuggestions
The maximum number of suggestions to show at a time.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoHelp
If set, don't show the user how to use the prompt (i.e.
'\[↑↓\] Change suggestion  \[Tab\] Pick suggestion  \[Enter\] Submit  \[Esc\] Cancel').
Only relevant if \`-Suggestions\` is set, as the help won't be shown without suggestions.

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

### -MaskInput
If set, replace the input with '*'.
This is similar to -MaskInput for the built-in Read-Host.
The returned value will still be what the user entered.

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

## INPUTS

## OUTPUTS

### The string the user entered.
## NOTES

## RELATED LINKS
