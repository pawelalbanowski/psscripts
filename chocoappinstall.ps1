# [Cmdletbinding()]
# param([switch] $fast)

# must provide tag for apps when launching script (at the time of editing this med/sekr/adm avaliable)

# get random seconds
# $rand = Get-Random -Minimum 900 -Maximum 1800
$rand = Get-Random -Minimum 30 -Maximum 90

# if($fast){
#     $rand = Get-Random -Minimum 30 -Maximum 90
# }


# format seconds into minutes and seconds
$min = [math]::Floor($rand / 60)
$sec = $rand % 60

# get username and split from domain name (szpitalsm\palbanowski)
$user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
$user = $user.split('\')[1]

# display warning with time left (if less than minute, only display seconds)
if ($min -eq 0) {
    $command = "msg $user Za $sec s rozpocznie sie aktualizacja aplikacji systemowych, przed nia wyswietlone zostanie powiadomienie. Prosze przerwac prace na jej czas."
}
else {
    $command = "msg $user Za $min min $sec s rozpocznie sie aktualizacja aplikacji systemowych, przed nia wyswietlone zostanie powiadomienie. Prosze przerwac prace na jej czas."
}
Invoke-Expression $command

Start-Sleep -Seconds $rand

# get user again in case changed, probably can omit but done just in case
$user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
$user = $user.split('\')[1]

$command = "msg $user Rozpoczynanie aktualizacji, potrwa okolo 5-10 minut. Prosze przerwac prace na jej czas. Po zakonczeniu pojawi sie potwierdzenie."
Invoke-Expression $command

$dirpath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Chocolatey"
$displayname = "Chocolatey Instalacja"
$displayversion = "1.1.0"
$publisher = "Chocolatey"
$state = "State"

if (!(test-path $dirpath)) {
    new-item -Path $dirpath -Force | Out-Null
    New-ItemProperty -path $dirpath -Name "DisplayName" -Value $displayname -PropertyType string | Out-Null
    New-ItemProperty -path $dirpath -Name "DisplayVersion" -Value $displayversion -PropertyType string | Out-Null
    New-ItemProperty -path $dirpath -Name "Publisher" -Value $publisher -PropertyType string | Out-Null
    New-ItemProperty -path $dirpath -Name "State" -Value $state -PropertyType string | Out-Null
}

# starting string to append to (choco-upgrade-all-at-startup has no tags so can be added manually)
$fullinstall = "C:\ProgramData\chocolatey\choco.exe install "
# $fullinstall += 'choco-upgrade-all-at-startup '

# install packages with tag (passed as arguments to program - $args is built in)
foreach ($tag in $args) {
    C:\ProgramData\chocolatey\choco.exe find $tag --by-tag-only -r | ForEach-Object {
        $fullinstall += "$($_.split('|')[0]) "
    }
}
Invoke-Expression "$($fullinstall) -y" | Out-Null


# uninstall eset pkg but leave app
# Invoke-Expression "C:\ProgramData\chocolatey\choco.exe uninstall eset -y" | Out-Null

try {
    foreach ($tag in $args) {
        if (Test-Connection 10.0.0.3 -quiet) {
            $local = invoke-expression "C:\ProgramData\chocolatey\choco.exe find $tag --by-tag-only -r -lo" 
            C:\ProgramData\chocolatey\choco.exe find $tag --by-tag-only -r | ForEach-Object {
                if (!($_ -in $local)) {
                    throw "App $_ missing from local repository"
                }
            }
        }
        else {
            throw "Connection error"
        }
    }
    if (test-path $dirpath) {
        Set-ItemProperty -path $dirpath -Name "DisplayName" -value "Chocolatey Gotowy"
    }

    # get user again just in case, again can be omitted probably
    $user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
    $user = $user.split('\')[1]
    $command = "msg $user Aktualizacja zakonczona."
    Invoke-Expression $command

}
catch {
    if (test-path $dirpath) {
        Set-ItemProperty -path $dirpath -Name "DisplayName" -value "Chocolatey Error"
    }
    $user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username
    $user = $user.split('\')[1]

    $command = "msg $user W aktualizacji wystapily bledy, prosze skontaktowac sie z dzialem IT"
    Invoke-Expression $command
}
