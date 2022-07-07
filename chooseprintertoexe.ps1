Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Security.Principal

# create and configure forms object
$window = New-Object System.Windows.Forms.Form
$window.Text = 'Drukarki'
$window.Size = New-Object System.Drawing.Size(245, 420)
$window.StartPosition = 'Manual'
$window.Location = New-Object System.Drawing.Point($([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width - $window.Width - 20), $([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Bottom - $window.Height - 40))

# create confirm button object
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(10, 315)
$okButton.Size = New-Object System.Drawing.Size(96,48)
$okButton.Text = 'Ustaw jako domyślną'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$window.AcceptButton = $okButton

# create cancel button object
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(125, 315)
$cancelButton.Size = New-Object System.Drawing.Size(96,48)
$cancelButton.Text = 'Anuluj'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

# add label to selection box
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,3)
$label.Size = New-Object System.Drawing.Size(280,15)
$label.Text = 'Wybierz drukarkę:'

# add selection box
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10,40)
$listBox.Size = New-Object System.Drawing.Size(200,40)
$listBox.Height= 260
$listBox.Width = 210

# add checkbox to switch between all/vlan only 
$Checkbox = new-object System.Windows.Forms.Checkbox
$Checkbox.Location = new-object System.Drawing.Size(10,17)

# Checkbox label
$Checkbox.size = new-object System.Drawing.Size(20, 20)
$chklabel = new-object System.Windows.Forms.Label
$chklabel.Location = new-object System.Drawing.Size(30,20)
$chklabel.size = new-object System.Drawing.Size(200,15)
$chklabel.Text = "Pokaż ze wszystkich lokalizacji"

# label2 for countdown
$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10,295)
$label2.Size = New-Object System.Drawing.Size(280,20)

# Label3 for ip
$label3 = New-Object System.Windows.Forms.Label
$label3.Location = New-Object System.Drawing.Point(10,365)
$label3.Size = New-Object System.Drawing.Size(280,20)

# Timer
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 1000
$window.Controls.Add($label2)
$window.Controls.Add($okButton)

# configure timer
$Script:Countdown = 60
$okButton.Add_Click({Button_Click})
$Timer.Add_Tick({Timer_Tick})

# sets countdown variable back to 60
Function ClearAndClose()
 {
    $Timer.Stop(); 
    $window.Close(); 
    $window.Dispose();
    $Timer.Dispose();
    $Script:CountDown=60
 }

 Function Button_Click()
 {
    ClearAndClose
 }

 # countdown
 Function Timer_Tick()
 {
    $Label2.Text = "Okno zamknie się za $Script:CountDown s"
         --$Script:CountDown
         if ($Script:CountDown -lt 0)
         {
            ClearAndClose
         }
 }

 # gets vlan 
$ips = (Get-NetIPConfiguration).IPv4Address.IPAddress
    ForEach($i in $ips) {if ($i.StartsWith("10")) {$ip = $i}}
    $octets = $ip -split "\."
    $newip = $octets[0, 1, 2]
 
    $newip = $newip -join "."

$notVlan = [System.Collections.ArrayList]@()

# if on terminal
if([regex]::Escape($newip) -eq [regex]::Escape('10.0.0')){
    $NTUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $UserName = $NTUserName.Split('\')[-1]

    $Events =
        Get-WinEvent -FilterHashtable @{ LogName = "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational"; Id = 1149} |
        Select-Object *,
        @{ Name = 'UserName'; Expression = { $_.Properties[0].Value } },
        @{ Name = 'SourceIP'; Expression = { $_.Properties[2].Value } } |
        Group-Object -Property UserName -AsHashTable -AsString
    if ($null -ne $Events) {
        $LastEvent = ($Events[$UserName] | Sort-Object TimeCreated)[-1]
        $octets = $LastEvent.SourceIP -split "\."
        $newip = $octets[0, 1, 2]
 
        $newip = $newip -join "."
    } else {$newip = "10."}
}

# get default printer
$default = (Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true" | Select-Object Name).Name

# add printers that match vlan
Get-Printer | Sort-Object | Where-Object PortName -Match $newip | ForEach-Object {
        [void]$listBox.Items.Add(($_.Name -split "\\")[-1])
    if ([regex]::Escape(($_.Name -split "\\")[-1]) -eq [regex]::Escape(($default -split "\\")[-1])) {
        $listBox.SelectedItem = $listBox.Items[[array]::IndexOf($listBox.Items, ($_.Name -split "\\")[-1])]
    }
}

# add printers outside of vlan for checkbox
Function Add-Others() {
    Get-Printer | Sort-Object |Where-Object PortName -NotMatch $newip | Where-Object PortName -NotMatch "USB" | ForEach-Object {
        if($_.Name -ne "Microsoft Print to PDF" -and $_.Name -ne "OneNote for Windows 10") {
            [void]$listBox.Items.Add(($_.Name -split "\\")[-1])
        $notVlan.Add(($_.Name -split "\\")[-1])
    }
    if ([regex]::Escape(($_.Name -split "\\")[-1]) -eq [regex]::Escape(($default -split "\\")[-1])) {
        $listBox.SelectedItem = $listBox.Items[[array]::IndexOf($listBox.Items, ($_.Name -split "\\")[-1])]
    }
        }
}

# remove other printers after unchecking
Function Remove-Others() {
    foreach ($p in $notVlan) {
    $listBox.Items.Remove($p)
    }
}

# on state changed, act accordingly
$Checkbox.Add_CheckStateChanged({
    If ($Checkbox.Checked) {
        Add-Others
    } Else {
        Remove-Others
    }
})

# add usb printers
Get-Printer | Sort-Object | ForEach-Object {
    if ($_.PortName.StartsWith("USB")) {
        [void]$listBox.Items.Add(($_.Name -split "\\")[-1])
    }
    if ([regex]::Escape(($_.Name -split "\\")[-1]) -eq [regex]::Escape(($default -split "\\")[-1])) {
        $listBox.SelectedItem = $listBox.Items[[array]::IndexOf($listBox.Items, ($_.Name -split "\\")[-1])]
    }
}


# add vlan label
$label3.Text = $newip + ".0"

# add everything to forms object
$window.TopMost = $true

$window.Controls.Add($listBox)
$window.controls.Add($label)
$window.controls.Add($label2)
$window.controls.Add($label3)
$window.Controls.Add($okButton)
$window.Controls.Add($cancelButton)
$window.Controls.Add($Checkbox)
$window.Controls.Add($chklabel)
$Timer.Start()

$result = $window.ShowDialog()

# change default printer
if ($result -eq [System.Windows.Forms.DialogResult]::OK){
    if ($ListBox.SelectedIndices.Count -eq 1){
        $x = $listBox.SelectedItem
        $x = [regex]::Escape($x)
        $x = (Get-Printer | Where-Object Name -Match $x).Name
        $printer = Get-CimInstance -Class Win32_Printer | Where-Object Name -eq $x
        Invoke-CimMethod -InputObject $printer -MethodName SetDefaultPrinter | out-null
    }
}