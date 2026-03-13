function ConvertTo-ObsidianEncodedPath {
    <#
    .SYNOPSIS
        Normalizes and URL-encodes a vault path for use in API URIs.
    .DESCRIPTION
        Converts backslashes to forward slashes and URL-encodes each path segment.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $normalized = $Path.Replace('\', '/')
    ($normalized -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }) -join '/'
}
