
write "1 {"Frühstück"}"
write "2 {"Mittag"}"
write "3 {"Abendessen"}"

$s = Read-Host "Gib was ein"

switch($s){
1 {"Frühstück"}
2 {"Mittag"}
3 {"Abendessen"}
default {"nix davon"} 
}