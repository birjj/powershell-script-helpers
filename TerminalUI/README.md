# TerminalUI

Various CLI-based user interfaces that attempt to improve on the built-in PowerShell variants.

The following is currently implemented:

## Get-UserInput

Allows the user to enter an arbitrary text input, but supports suggestions. Useful for cases where you want to give the user multiple options to choose from, but also the ability to enter new values.

Can be used as a replacement for the built-in `Read-Host`, and supports the same options (except for `-AsSecureString`).  
See [the docs page](docs/Get-UserInput.md) for details.

<div align="center">

[![Screenshot of Get-UserInput being called](https://user-images.githubusercontent.com/4542461/218481009-3e1473c9-5e46-4472-90b0-b0f3f762698c.png)](https://asciinema.org/a/559512)
  
</div>

## Get-UserChoice

Asks the user to pick one (or more) of the available options.

Can be used as a replacement for the built-in `$Host.UI.PromptForChoice` (although it currently does not support all of the same options).  
See [the docs page](docs/Get-UserChoice.md) for details.

<div align="center">
  
[![Screenshot of Get-UserChoice being called](https://user-images.githubusercontent.com/4542461/218476951-09afc950-5333-4c08-99cc-dcfae343b65b.png)](https://asciinema.org/a/lIJcI64CmcxEBCAZFoNvnuOFJ)

</div>
