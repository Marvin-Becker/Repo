<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Test
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$TestForm                    = New-Object system.Windows.Forms.Form
$TestForm.ClientSize         = New-Object System.Drawing.Point(400,400)
$TestForm.text               = "Form"
$TestForm.TopMost            = $false
$TestForm.BackColor          = [System.Drawing.ColorTranslator]::FromHtml("#ded3d3")

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 291
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(48,32)
$TextBox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "checkBox"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 95
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(39,77)
$CheckBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$Values = @("Hannover", "Hamburg", "Leipzig")

ForEach ($Value in $Values) {
    	$ComboBox1.Items.Add($Value) 
    }
$ComboBox1.width                 = 312
$ComboBox1.height                = 20
$ComboBox1.location              = New-Object System.Drawing.Point(35,121)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,220)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = „OK“
$OKButton.DialogResult = „OK“
$OKButton.Add_Click({$TestForm.Close()})
$TestForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,220)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = „Cancel“
$CancelButton.DialogResult = „Cancel“
$CancelButton.Add_Click({$TestForm.Close()})
$TestForm.Controls.Add($CancelButton)



$TestForm.controls.AddRange(@($TextBox1,$CheckBox1,$ComboBox1)) 

$TextBox1.Add_AcceptsTabChanged({  }) 

$TestForm.ShowDialog() 



If ($TestForm.DialogResult -like „OK“) {

$ComboBox1.text
$TextBox1.text
$CheckBox1.Checked

} else {„Abbruch geklickt“}

pause