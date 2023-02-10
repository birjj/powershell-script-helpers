---
Module Name: TerminalUI
Module Guid: cc5ad44f-8057-4eee-93bc-287f9eca6fab
Download Help Link: NA
Help Version: 0.0.2
Locale: en-US
---

# TerminalUI Module
## Description
Various CLI-based user interfaces that attempt to improve on the built-int PowerShell variants

## TerminalUI Cmdlets
### [Get-UserChoice](Get-UserChoice.md)
Prompts the user to choose one of multiple options. Similar to $Host.UI.PromptForChoice, but with a different UI and more options.

### [Get-UserInput](Get-UserInput.md)
Prompts the user for text input. Similar to Read-Host, but with suggestions support.

### [New-UserChoiceItem](New-UserChoiceItem.md)
Creates a new item for use with Get-UserChoice. Should only be used if you need to display something other than the value the item represents.

### [New-UserInputSuggestion](New-UserInputSuggestion.md)
Creates a new suggestion for use with Get-UserInput. Should only be used if you need to display something other than the value the suggestion represents.


