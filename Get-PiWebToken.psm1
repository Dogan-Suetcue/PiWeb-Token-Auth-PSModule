$ErrorActionPreference = 'Stop'

$global:ERROR_REPORT_PATH = "$($PSScriptRoot)\Error.log"
$global:TOKEN_PATH = "$($PSScriptRoot)\token.json"

function Get-PiWebToken ([string]$baseAddress) {
    Get-PSAuthClientModule

    if (Test-Path -Path $global:TOKEN_PATH) {
        $token = Get-Content -Path $global:TOKEN_PATH | ConvertFrom-Json

        if (([System.DateTime]::Now -ge $token.expiry_datetime) -and ($token.scope.Contains("offline_access"))) {
            $updatedToken = Update-PiWebToken $token

            Save-Token $global:TOKEN_PATH $updatedToken

            return $updatedToken
        }
        else {
            return $token
        }
    }
    else {
        $token = New-PiWebToken $baseAddress

        Save-Token $global:TOKEN_PATH $token

        return $token
    }
}

function Get-PSAuthClientModule {
    if (Get-Module -Name PSAuthClient -ListAvailable) {
        Import-Module -Name PSAuthClient -MinimumVersion 1.3.0 -MaximumVersion 1.3.0
    }
    else {
        try {
            Install-Module -Name PSAuthClient -MinimumVersion 1.3.0 -MaximumVersion 1.3.0 -Scope CurrentUser -Force
            Import-Module -Name PSAuthClient -MinimumVersion 1.3.0 -MaximumVersion 1.3.0
        }
        catch {
            Write-Error "Failed to install PSAuthClient module. Please contact your system administrator for assistance."
            exit    
        }
    }
}

function Update-PiWebToken ([PSCustomObject]$token, [string]$baseAddress) {
    try {
        $openIdConfiguration = Get-OpenIdConfiguration $baseAddress
        $token | Add-Member -MemberType NoteProperty -Name "uri" -Value $openIdConfiguration.token_endpoint
        $token | Add-Member -MemberType NoteProperty -Name $global:CLIENT_ID.Name -Value $global:CLIENT_ID.Value
        $token = Invoke-OAuth2TokenEndpoint -uri $token.uri -client_id $token.client_id -refresh_token $token.refresh_token -scope $token.scope
        return $token   
    }
    catch {
        Write-Error "Failed to update token: $($_.Exception.Message)"
        Set-Content -Path $global:ERROR_REPORT_PATH -Value $Error
    }
}

function New-PiWebToken ([string]$baseAddress) {
    try {
        $openIdConfiguration = Get-OpenIdConfiguration $baseAddress
        $authorization_endpoint = $openIdConfiguration.authorization_endpoint
        $token_endpoint = $openIdConfiguration.token_endpoint

        $oAuthConfiguration  = Get-OAuthConfiguration $baseAddress
        $parameters = @{
            client_id        = $oAuthConfiguration.upstreamTokenInformation.clientId
            scope            = $oAuthConfiguration.upstreamTokenInformation.requestedScopes
            redirect_uri     = $oAuthConfiguration.upstreamTokenInformation.redirectUri
            uri              = $authorization_endpoint
        }

        $response = Invoke-OAuth2AuthorizationEndpoint @parameters

        $parameters = $response
        $parameters.Add("uri", $token_endpoint)
        $token = Invoke-OAuth2TokenEndpoint @parameters

        return $token
    }
    catch {
        Write-Error "Failed to create new token: $($_.Exception.Message)"
        Set-Content -Path $global:ERROR_REPORT_PATH -Value $Error[0].ErrorDetails.Message
    }
}

function Save-Token([string]$tokenPath, [PSCustomObject]$token) {
    Set-Content -Path $tokenPath -Value ($token | ConvertTo-Json)
}

function Get-OAuthConfiguration([string]$baseAddress) {
    try {
        $oAuthConfigurationUrl  = "$($baseAddress)/OAuthServiceRest/oAuthConfiguration"
        $oAuthConfiguration = Invoke-RestMethod -Method Get -Uri $oAuthConfigurationUrl 
        return $oAuthConfiguration
    }
    catch {
        Write-Error "Failed to get OAuth configuration: $($_.Exception.Message)"
        Set-Content -Path $global:ERROR_REPORT_PATH -Value $Error
    }
}

function Get-OpenIdConfiguration ([string]$baseAddress) {
    try {
        $openIdConfigurationUrl  = "$($baseAddress)/OAuthServiceRest/oauthConfiguration"
        $response = Invoke-RestMethod -Method Get -Uri $openIdConfigurationUrl 

        $openIdUrl = "$($response.upstreamTokenInformation.openIdAuthority)/.well-known/openid-configuration"
        $openIdConfiguration = Invoke-RestMethod -Method Get -Uri $openIdUrl
        return $openIdConfiguration
    }
    catch {
        Write-Error "Failed to get OpenID configuration: $($_.Exception.Message)"
        Set-Content -Path $global:ERROR_REPORT_PATH -Value $Error
    }
}

Export-ModuleMember -Function Get-PiWebToken