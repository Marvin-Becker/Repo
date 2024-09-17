function Generate-ICDCodesWithWords {
    param (
        [string]$prefix = "M",
        [int]$start = 1,
        [int]$end = 9
    )

    # Wörter für Zahlen 0-9 und Zehnerzahlen
    $numbers = @{
        0  = 'null'
        1  = 'ein'
        2  = 'zwei'
        3  = 'drei'
        4  = 'vier'
        5  = 'fünf'
        6  = 'sechs'
        7  = 'sieben'
        8  = 'acht'
        9  = 'neun'
        10 = 'zehn'
        11 = 'elf'
        12 = 'zwölf'
        13 = 'dreizehn'
        14 = 'vierzehn'
        15 = 'fünfzehn'
        16 = 'sechzehn'
        17 = 'siebzehn'
        18 = 'achtzehn'
        19 = 'neunzehn'
        20 = 'zwanzig'
        30 = 'dreißig'
        40 = 'vierzig'
        50 = 'fünfzig'
        60 = 'sechzig'
        70 = 'siebzig'
        80 = 'achtzig'
        90 = 'neunzig'
    }

    # Funktion zur Umwandlung einer Zahl in Worte
    function Convert-NumberToWords {
        param([int]$num)

        if ($num -lt 10) {
            return $numbers[$num] -replace '^ein$', 'eins'
        } elseif ($num -lt 20) {
            return $numbers[$num]
        } else {
            $tensPart = $numbers[$num - ($num % 10)]
            $digitPart = $numbers[$num % 10]

            # Kein führendes 'nullund' bei ganzen Zehnern
            if ($num % 10 -eq 0) {
                return $tensPart
            } else {
                return "$($digitPart)und$($tensPart)"
            }
        }
    }

    # Generiere alle ICD-Codes
    for ($i = $start; $i -le $end; $i++) {
        for ($j = 0; $j -le 99; $j++) {
            $icdCode = "{0}{1:D2}.{2:D2}" -f $prefix, $i, $j
            $textCode = "M {0} punkt {1}" -f (Convert-NumberToWords $i), (Convert-NumberToWords $j)
            Write-Output "$icdCode\\$textCode"
        }
    }
}

# Beispiel-Aufruf
Generate-ICDCodesWithWords >> $env:tempfile

### Version 2
function Generate-ICDCodesWithWords {
    param (
        [string]$prefix = "M",
        [int]$start = 1,
        [int]$end = 99
    )

    # Wörter für Zahlen 0-9 und Zehnerzahlen
    $numbers = @{
        0  = 'null'
        1  = 'ein'
        2  = 'zwei'
        3  = 'drei'
        4  = 'vier'
        5  = 'fünf'
        6  = 'sechs'
        7  = 'sieben'
        8  = 'acht'
        9  = 'neun'
        10 = 'zehn'
        11 = 'elf'
        12 = 'zwölf'
        13 = 'dreizehn'
        14 = 'vierzehn'
        15 = 'fünfzehn'
        16 = 'sechzehn'
        17 = 'siebzehn'
        18 = 'achtzehn'
        19 = 'neunzehn'
        20 = 'zwanzig'
        30 = 'dreißig'
        40 = 'vierzig'
        50 = 'fünfzig'
        60 = 'sechzig'
        70 = 'siebzig'
        80 = 'achtzig'
        90 = 'neunzig'
    }

    # Funktion zur Umwandlung einer Zahl in Worte
    function Convert-NumberToWords {
        param([int]$num, [bool]$isLeadingZero = $false)

        if ($num -lt 10) {
            if ($isLeadingZero -and $num -eq 0) {
                return 'null'
            }
            return $numbers[$num] -replace '^ein$', 'eins'
        } elseif ($num -lt 20) {
            return $numbers[$num]
        } else {
            $tensPart = $numbers[$num - ($num % 10)]
            $digitPart = $numbers[$num % 10]

            # Kein führendes 'nullund' bei ganzen Zehnern
            if ($num % 10 -eq 0) {
                return $tensPart
            } else {
                return "$($digitPart)und$($tensPart)"
            }
        }
    }

    # Generiere alle ICD-Codes
    for ($i = $start; $i -le $end; $i++) {
        for ($j = 0; $j -le 99; $j++) {
            # Einstelligkeit der Haupt- und Nebenzahlen berücksichtigen
            $icdCode = "{0}{1}.{2}" -f $prefix, ($i -lt 10 ? $i : "{0:D2}" -f $i), ($j -lt 10 ? $j : "{0:D2}" -f $j)
            $iText = Convert-NumberToWords -num $i -isLeadingZero ($i -lt 10)
            $jText = Convert-NumberToWords -num $j -isLeadingZero ($j -lt 10)
            $textCode = "M {0} punkt {1}" -f $iText, $jText
            Write-Output "$icdCode\\$textCode"
        }
    }
}

# Beispiel-Aufruf
Generate-ICDCodesWithWords | Out-File $env:tempfile
