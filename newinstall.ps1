# enable local admin, remove "U" account
Get-LocalUser -Name "Administrator" | Enable-LocalUser -Confirm:$false
try {
    Get-LocalUser -Name "U" -ErrorAction Stop | Remove-LocalUser -Confirm:$false
} catch  {
    Write-Host 'Local user not found, nothing has been deleted'
}

# disable ipv6 on ethernet
Disable-NetAdapterBinding -Name 'Ethernet' -ComponentID 'ms_tcpip6'

#disable wifi and bluetooth
get-netadapter | ForEach-Object {
    if (($_.Name -match 'Bluetooth') -or ($_.Name -match 'Wi-Fi')) {
        Disable-NetAdapter -Name $_.Name -Confirm:$false
    }
}

# install fonts and bginfo
& "\\10.0.0.12\_terminalRO\misc.exe" | Out-Null

# install choco
& "\\10.0.0.12\_terminalRO\choco\chocoinstall.exe" | Out-Null

# refresh env variables for choco commands to work after
refreshenv

# remove official repo and add wsm
choco source remove -n=chocolatey
choco source add -n=wsm -s="\\10.0.0.12\_terminalRO\choco"

# base install command with no tag pkgs
$fullinstall = "choco install "  # $fullinstall += 'choco-upgrade-all-at-startup '

# install packages with tag
$vncpassw, $tags = $args
foreach ($tag in $tags) {
    choco find $tag --by-tag-only -r | ForEach-Object {
        $fullinstall += "$($_.split('|')[0]) "
    }
}
Invoke-Expression "$($fullinstall) -y"

# set vnc password
& "\\10.0.0.12\_terminalRO\choco\install\UltraVNC\createpassword64.exe" 1 $vncpassw | Out-Null

# install PSWindowsUpdate
Install-PackageProvider NuGet -Force -Confirm:$false
Set-PSRepository PSGallery -InstallationPolicy Trusted
Install-Module PSWindowsUpdate -Repository PSGallery -Confirm:$false

# update windows
Get-WindowsUpdate -Install -Confirm:$false
