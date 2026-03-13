function Connect-ObsidianApi {
    <#
    .SYNOPSIS
        Connects to the Obsidian Local REST API.
    .DESCRIPTION
        Sets the API key and base URL for subsequent Obsidian API calls.
        Validates the connection by calling the server status endpoint.
        The API key is held in session memory until Disconnect-ObsidianApi
        is called or the module is removed.
    .PARAMETER ApiKey
        The API key from Obsidian Settings > Local REST API.
    .PARAMETER BaseUrl
        The base URL of the Obsidian Local REST API. Defaults to https://127.0.0.1:27124.
    .PARAMETER SkipCertificateCheck
        Skip TLS certificate validation. Defaults to true for localhost addresses.
    .EXAMPLE
        Connect-ObsidianApi -ApiKey 'your-api-key-here'
    .EXAMPLE
        $key = Import-Clixml -Path .\ObsidianLocalRestApiKey.xml
        Connect-ObsidianApi -ApiKey $key
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ApiKey,

        [string]$BaseUrl = 'https://127.0.0.1:27124',

        [switch]$SkipCertificateCheck
    )

    $script:ApiKey = $ApiKey
    $script:BaseUrl = $BaseUrl.TrimEnd('/')

    # Default SkipCertificateCheck to true for localhost, false otherwise
    if ($PSBoundParameters.ContainsKey('SkipCertificateCheck')) {
        $script:SkipCertCheck = $SkipCertificateCheck.IsPresent
    }
    else {
        $uri = [uri]$script:BaseUrl
        $script:SkipCertCheck = $uri.Host -in @('127.0.0.1', 'localhost', '::1')
    }

    try {
        $status = Invoke-ObsidianRestMethod -Uri '/'
    }
    catch {
        $script:ApiKey = $null
        $script:BaseUrl = $null
        throw "Failed to connect to Obsidian API at $BaseUrl`: $_"
    }

    if (-not $status.authenticated) {
        $script:ApiKey = $null
        $script:BaseUrl = $null
        throw 'Authentication failed. The API key was not accepted by the Obsidian server.'
    }

    Write-Verbose "Connected to $($status.service) v$($status.versions.self) (Obsidian API v$($status.versions.obsidian))"
    $status
}
