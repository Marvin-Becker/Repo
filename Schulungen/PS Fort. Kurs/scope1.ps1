

$a=1


function f1 {
$b=2
$script:c=$a+$b
$global:d=$c*$b
write "F1:   A: $a   B: $b   C: $c   D: $d   E: $e"
}


f1

write "Script1:  A: $a   B: $b   C: $c   D: $d   E: $e"