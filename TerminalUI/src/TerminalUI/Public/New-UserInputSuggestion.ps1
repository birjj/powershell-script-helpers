<#
.SYNOPSIS
    Creates a new suggestion for use with Get-UserInput. Should only be used if you need to display something other than the value the suggestion represents.
.DESCRIPTION
    Creates a new suggestion for use with Get-UserInput.
    Normally you'd simply pass a string to Get-UserInput, but in some cases you want to display something other than the suggestion value.
    In those cases you can create a suggestion using New-UserInputSuggestion that has a display string and a value.
.EXAMPLE
    C:\PS> Get-UserInput -Suggestions @(New-UserInputSuggestion 'Foo')
    $ Will display the suggestion as 'Foo', when chosen will enter 'Foo'
.EXAMPLE
    C:\PS> Get-UserInput -Suggestions @(New-UserInputSuggestion -Value 'Foo' -Display 'Metasyntactic variable')
    $ Will display the suggestion as 'Metasyntactic variable', when chosen will enter 'Foo'
.EXAMPLE
    C:\PS> Get-UserInput -Suggestions @(New-UserInputSuggestion 'Foo' 'Metasyntactic variable')
    $ Will display the suggestion as 'Metasyntactic variable', when chosen will enter 'Foo'
.PARAMETER Value
    The value to enter when the suggestion is chosen.
.PARAMETER Display
    The string to display in the suggestions list.
.OUTPUTS
    An instance of the internal `[UserInputSuggestion]` class.
#>
function New-UserInputSuggestion {
    param(
        [Parameter(Mandatory = $true)][string] $Value,
        [Parameter(Mandatory = $false)][string] $Display = $Value
    )

    return [UserInputSuggestion]::new($Value, $Display)
}

class UserInputSuggestion {
    [string] $Value
    [string] $Display
    UserInputSuggestion([string] $Value, [string] $Display) {
        $this.Value = $Value
        $this.Display = $Display
    }
}
