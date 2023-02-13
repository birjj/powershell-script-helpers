<#
.SYNOPSIS
    Creates a new item for use with Get-UserChoice. Should only be used if you need to display something other than the value the item represents.
.DESCRIPTION
    Creates a new item for use with Get-UserChoice.
    Normally you'd simply pass a string to Get-UserChoice, but in some cases you want to display something other than the item value.
    In those cases you can create an item using New-UserChoiceItem that has a display string and a value.
.EXAMPLE
    C:\PS> Get-UserChoice @(New-UserChoiceItem 'Foo')
    $ Will display the item as 'Foo', when chosen will return 'Foo'
.EXAMPLE
    C:\PS> Get-UserChoice @(New-UserChoiceItem -Value 'Foo' -Display 'Metasyntactic variable')
    $ Will display the item as 'Metasyntactic variable', when chosen will enter 'Foo'
.EXAMPLE
    C:\PS> Get-UserInput @(New-UserChoiceItem 'Foo' 'Metasyntactic variable')
    $ Will display the item as 'Metasyntactic variable', when chosen will enter 'Foo'
.PARAMETER Value
    The value to return when the item is chosen.
.PARAMETER Display
    The string to display in the item list.
.OUTPUTS
    An instance of the internal `[UserChoiceItem]` class.
#>
function New-UserChoiceItem {
    param(
        [Parameter(Mandatory = $true)][object] $Value,
        [Parameter(Mandatory = $false)][string] $Display = $Value
    )

    return [UserChoiceItem]::new($Value, $Display)
}

class UserChoiceItem {
    [object] $Value
    [string] $Display
    UserChoiceItem([object] $Value, [string] $Display) {
        $this.Value = $Value
        $this.Display = $Display
    }
}
