function Disconnect-ObsidianApi {
    <#
    .SYNOPSIS
        Disconnects from the Obsidian Local REST API.
    .DESCRIPTION
        Clears the stored API key and base URL from module scope.
    .EXAMPLE
        Disconnect-ObsidianApi
    #>
    [CmdletBinding()]
    param()

    $script:ApiKey = $null
    $script:BaseUrl = $null
    $script:SkipCertCheck = $true
    Write-Verbose 'Disconnected from Obsidian API.'
}
