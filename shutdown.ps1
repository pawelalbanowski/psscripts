$dirpath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Chocolatey"
$displayname = "Chocolatey Instalacja"
$displayversion = "2.2.2"
$publisher = "Chocolatey"
$state = "State"

$errchk = 0
$PCName = $env:COMPUTERNAME
$PSDefaultParameterValues = @{}
$PSDefaultParameterValues += @{'New-RegKey:ErrorAction' = 'SilentlyContinue'}

function ErrorReport {
    param (
        $msg
    )
    $httpBody = '{
        "text": "' + $msg + '"
    }'

    try {
        $null = Invoke-WebRequest -Uri 'https://im.szpitalsm.local/hooks/66541a08def1fde2f7f9ff23/BjezPhJH3GLpk7r9v6sSZQiHJtXbfhBuKWJnMEBduwfBXmNb' -Method Post -Body $httpBody -ContentType 'application/json' -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host $_.Exception.Message
    }
}

function fnLN {
    $MyInvocation.ScriptLineNumber
}

try {
    if (!(Test-Path $dirpath)) {
        New-Item -Path $dirpath -Force | Out-Null
        New-ItemProperty -Path $dirpath -Name "DisplayName" -Value $displayname -PropertyType String | Out-Null
        New-ItemProperty -Path $dirpath -Name "DisplayVersion" -Value $displayversion -PropertyType String | Out-Null
        New-ItemProperty -Path $dirpath -Name "Publisher" -Value $publisher -PropertyType String | Out-Null
        New-ItemProperty -Path $dirpath -Name "State" -Value $state -PropertyType String | Out-Null
    } else {
        Set-ItemProperty -Path $dirpath -Name "DisplayName" -Value "Chocolatey Instalacja"
    }
}
catch {
    ErrorReport "Registry Edit Error on $($PCName): $($_.Exception.Message) (Line $(fnLN))"
}


C:\ProgramData\chocolatey\choco.exe upgrade chocolatey -y

$apps = '7zip', 'firefox', 'libreoffice', 'vnc', 'liberica', 'ows'

try {
    C:\ProgramData\chocolatey\choco.exe install @($apps) -y
}
catch {
    ErrorReport "Group install Error on $($PCName): $($_.Exception.Message) (Line $(fnLN))"
}


foreach ($app in $apps) {
    $getapp = C:\ProgramData\chocolatey\choco.exe list $app -r
    if (!($getapp)) {
        $errchk = 1
        ErrorReport "Install Error on $($PCName): $app package not installed (Line $(fnLN))"
    }
}

try {
    get-package '*libre*'
}
catch {
    ErrorReport "App Error on $($PCName): $($_.Exception.Message) (Line $(fnLN))"
    C:\ProgramData\chocolatey\choco.exe install libreoffice -y --force
    C:\ProgramData\chocolatey\choco.exe upgrade libreoffice -y
}

if (Get-Package | Where-Object {$_.Name -like "*Thunderbird*"}) {
    C:\ProgramData\chocolatey\choco.exe install thunderbird -y
    $getapp = C:\ProgramData\chocolatey\choco.exe list thunderbird -r
    if (!($getapp)) {
        $errchk = 1
        ErrorReport "Install Error on $($PCName): thunderbird package not installed (Line $(fnLN))"
    }
}

if (Get-Package | Where-Object {$_.Name -like "*Rocket*"}) {
    C:\ProgramData\chocolatey\choco.exe install rocketchat -y
    $getapp = C:\ProgramData\chocolatey\choco.exe list rocketchat -r
    if (!($getapp)) {
        $errchk = 1
        ErrorReport "Install Error on $($PCName): rocketchat package not installed (Line $(fnLN))"
    }
}

if (Get-Package | Where-Object {$_.Name -like "*OpenWebStart*"}) {
    C:\ProgramData\chocolatey\choco.exe install ows -y
    $getapp = C:\ProgramData\chocolatey\choco.exe list ows -r
    if (!($getapp)) {
        $errchk = 1
        ErrorReport "Install Error on $($PCName): ows package not installed (Line $(fnLN))"
    }
}

if (Get-Package | Where-Object {$_.Name -like "Mozilla Firefox* (x86*"}) {
    C:\ProgramData\chocolatey\choco.exe install firefox --force -y
    if (get-package "Mozilla Firefox* (x86*") {
        ErrorReport "App Error on $($PCName): Could not uninstall Firefox x86 (Line $(fnLN))"
    }
}

if (Get-Package | Where-Object {$_.Name -like "Mozilla Thunderbird* (x86*"}) {
    C:\ProgramData\chocolatey\choco.exe install thunderbird --force -y
    if (get-package "Mozilla Thunderbird* (x86*") {
        ErrorReport "App Error on $($PCName): Could not uninstall Thunderbird x86 (Line $(fnLN))"
    }
}

if (Get-Package | Where-Object {$_.Name -like "Sentinel*"}) {
    C:\ProgramData\chocolatey\choco.exe install sentinel -y -n
}

if (Get-Package | Where-Object {$_.Name -like "Axence*"}) {
    C:\ProgramData\chocolatey\choco.exe install nvagent -y -n
}

try {
    C:\ProgramData\chocolatey\choco.exe upgrade all -y
}
catch {
    ErrorReport "App upgrade Error on $($PCName): $($_.Exception.Message) (Line $(fnLN))"
}


if ($errchk -eq 1) {
    Set-ItemProperty -Path $dirpath -Name "DisplayName" -Value "Chocolatey Error"
} else {
    Set-ItemProperty -Path $dirpath -Name "DisplayName" -Value "Chocolatey Gotowy"
}

# $packages = Get-Package *7-Zip* | Sort-Object -Property Version -Descending

# if ($packages.Count -gt 1) {
#     # insert code to remove old versions
# }
