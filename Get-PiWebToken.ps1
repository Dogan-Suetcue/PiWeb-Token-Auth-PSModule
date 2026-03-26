
Import-Module -Name .\Get-PiWebToken.psm1

$databaseIntanceId = "7752a068-16bb-456c-850c-db9291599a45"
$baseAddress = "https://piwebcloud-service.metrology.zeiss.com/$($databaseIntanceId)"
$token = Get-PiWebToken $baseAddress

function Get-Parts ([PSCustomObject]$token) {
    try {
        $headers = @{
            Authorization = "Bearer $($token.access_token)"
        }
        $parts = Invoke-RestMethod -Method Get -Uri "$($baseAddress)/dataServiceRest/parts" -Headers $headers
        $parts
    }
    catch {
        Set-Content -Path "$($PSScriptRoot)\Error.log" -Value $Error[0].ErrorDetails.Message
    }
}

Get-Parts $token