# people exporting using Import-Module can't access the class directly - give them a proxy function
function New-UserChoiceItem {
    param(
        [Parameter(Mandatory = $true)][string] $Value,
        [Parameter(Mandatory = $false)][string] $Display = $Value
    )

    return [UserChoiceItem]::new($Value, $Display)
}

class UserChoiceItem {
    [string] $Value
    [string] $Display
    UserChoiceItem([string] $Value, [string] $Display) {
        $this.Value = $Value
        $this.Display = $Display
    }
}
