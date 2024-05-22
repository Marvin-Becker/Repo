function Generate-RandomPassword {
    param (
        [int]$Length = 20
    )

    $letters = [char[]](65..90 + 97..122)  # A-Z, a-z
    $numbers = [char[]](48..57)           # 0-9
    $symbols = [char[]]('-_+()') # (33..47 + 58..64 + 91..96 + 123..126)  # Special characters

    $allChars = $letters + $numbers + $symbols

    $password = -join ((1..$length) | ForEach-Object {
            $allChars | Get-Random
        })

    return $password
}
