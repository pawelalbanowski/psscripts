$rand = Get-Random -Minimum 30 -Maximum 90
$user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username.split('\')[1]

if ($rand -lt 60) {
    $command = "msg $user Za $rand s rozpocznie sie aktualizacja aplikacji systemowych, przed nia wyswietlone zostanie powiadomienie. Prosze przerwac prace na jej czas."
} else {
    $min = [math]::Floor($rand / 60)
    $sec = $rand % 60
    $command = "msg $user Za $min min $sec s rozpocznie sie aktualizacja aplikacji systemowych, przed nia wyswietlone zostanie powiadomienie. Prosze przerwac prace na jej czas."
}

Invoke-Expression $command
Start-Sleep -Seconds $rand

$user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username.split('\')[1]
$command = "msg $user Rozpoczynanie aktualizacji, potrwa okolo 5-10 minut. Prosze przerwac prace na jej czas. Po zakonczeniu pojawi sie potwierdzenie."
Invoke-Expression $command

$dirpath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Chocolatey"
$displayname = "Chocolatey Instalacja"
$displayversion = "1.3.0"
$publisher = "Chocolatey"
$state = "State"

if (!(Test-Path $dirpath)) {
    New-Item -Path $dirpath -Force | Out-Null
    New-ItemProperty -Path $dirpath -Name "DisplayName" -Value $displayname -PropertyType string | Out-Null
    New-ItemProperty -Path $dirpath -Name "DisplayVersion" -Value $displayversion -PropertyType string | Out-Null
    New-ItemProperty -Path $dirpath -Name "Publisher" -Value $publisher -PropertyType string | Out-Null
    New-ItemProperty -Path $dirpath -Name "State" -Value $state -PropertyType string | Out-Null
}

$fullinstall = "C:\ProgramData\chocolatey\choco.exe install "
foreach ($tag in $args) {
    C:\ProgramData\chocolatey\choco.exe find $tag --by-tag-only -r | ForEach-Object {
        $fullinstall += "$($_.split('|')[0]) "
    }
}
Invoke-Expression "$($fullinstall) -y" | Out-Null

try {
    foreach ($tag in $tags) {
        if (Test-Connection 10.0.0.3 -quiet) {
            $local = invoke-expression "C:\ProgramData\chocolatey\choco.exe find $tag --by-tag-only -r -lo" 
            C:\ProgramData\chocolatey\choco.exe find $tag --by-tag-only -r | ForEach-Object {
                if (!($_ -in $local)) {
                    throw "App $_ missing from local repository"
                }
            }
        } else {
            throw "Connection error"
        }
    }
    if (Test-Path $dirpath) {
        Set-ItemProperty -Path $dirpath -Name "DisplayName" -Value "Chocolatey Gotowy"
    }

    $user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username.split('\')[1]
    $command = "msg $user Aktualizacja zakonczona."
    Invoke-Expression $command
} catch {
    if (Test-Path $dirpath) {
        Set-ItemProperty -Path $dirpath -Name "DisplayName" -Value "Chocolatey Error"
    }
    $user = (Get-CimInstance -ClassName Win32_ComputerSystem).Username.split('\')[1]
    $command = "msg $user W aktualizacji wystapily bledy, prosze skontaktowac sie z dzialem IT"
    Invoke-Expression $command
    throw "App install error"
}