
function New-Password {
    param(
        [Parameter(Mandatory = $false,
            Position = 0)]
        [ValidateRange(8, 100)]
        [int]$Length = 8,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeUppercase = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeLowercase = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeNumbers = $true,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeSpecialCharacters = $true
    )

    $characters = [System.Collections.Generic.List[char]]::new()  

    if ($IncludeUppercase) {
        $characters += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.GetEnumerator()
    }

    if ($IncludeLowercase) {
        $characters += 'abcdefghijklmnopqrstuvwxyz'.GetEnumerator()
    }

    if ($IncludeNumbers) {
        $characters += '0123456789'.GetEnumerator()
    }

    if ($IncludeSpecialCharacters) {
        $characters += '!@#$%^&*()'.GetEnumerator()
    }

    $password = [System.Collections.Generic.List[char]]::new($Length)
    $random = [System.Random]::new()

    for ($i = 0; $i -lt $Length; $i++) {
        $password += $characters[$random.Next(0, $characters.Length)]
    }

    return $password -join ''
}
