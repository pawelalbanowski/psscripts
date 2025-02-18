
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

$PCName = $env:COMPUTERNAME
ErrorReport "Test error message from **$PCName**:\n test"


