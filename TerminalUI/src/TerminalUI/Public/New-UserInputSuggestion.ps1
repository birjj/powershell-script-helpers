# people exporting using Import-Module can't access the class directly - give them a proxy function
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
