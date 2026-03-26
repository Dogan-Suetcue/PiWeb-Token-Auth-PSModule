# OIDC Token Authentication PowerShell Module

This PowerShell module contains the Get-PiWebToken function that allows you to retrieve a PiWeb token. The module uses the [PSAuthClient](https://github.com/alflokken/PSAuthClient) module to perform authentication against the external OIDC Identity Provider configured in PiWeb Server. The token can be used for authentication with the [PiWeb API](https://zeiss-piweb.github.io/PiWeb-Api/general).

⚠ **Warning:** Please note that the token is stored in plain text in the token.json file. You are responsible for encrypting the file yourself.

## Prerequisites

Before you can use this module, you need to install the PSAuthClient module. To do this, run the following command in PowerShell as an administrator:

```powershell
Install-Module -Name PSAuthClient -MinimumVersion 1.3.0 -MaximumVersion 1.3.0 -Scope CurrentUser -Force
```

## Usage

### Example 1: Retrieving Token from a Self-Hosted Identity Server

This example demonstrates how to retrieve a token from a self-hosted Identity Server and use it to access resources.

```powershell
Import-Module -Name .\Get-PiWebToken.psm1

$baseAddress = "https://<PiWeb Server Hostname>:<Port>"
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
```

### Example 2: Retrieving Token from PiWeb Cloud Server

This example demonstrates how to retrieve a token from the PiWeb Cloud Server and use it to access resources.

```powershell
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
```

Further information on using the PiWeb API can be found on the official site [here](https://zeiss-piweb.github.io/PiWeb-Api/general).

## License

[MIT](https://choosealicense.com/licenses/mit/)
