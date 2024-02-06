for($i=1; $i -le 1000; $i++)
{
new-item c:\test4\testneu$i.txt -ItemType File
}


$i=1
while ($i -le 10)
{write $i
$i++}


$i=1
do
{write $i
$i++}
while ($i -le 10)


$i=1
do
{write $i
$i++}
until ($i -gt 10)



