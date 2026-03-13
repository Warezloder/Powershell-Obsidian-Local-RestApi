function Search-ObsidianVaultSimple {
    <#
    .SYNOPSIS
        Performs a simple text search across the Obsidian vault.
    .DESCRIPTION
        Calls POST /search/simple/ with a text query. Returns matching files
        with context around each match.
    .PARAMETER Query
        The text to search for.
    .PARAMETER ContextLength
        How many characters of context to return around each match. Defaults to 100.
    .EXAMPLE
        Search-ObsidianVaultSimple -Query 'meeting notes'
    .EXAMPLE
        Search-ObsidianVaultSimple -Query 'TODO' -ContextLength 200
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [ValidateRange(1, [int]::MaxValue)]
        [int]$ContextLength = 100
    )

    $encodedQuery = [uri]::EscapeDataString($Query)
    $uri = "/search/simple/?query=$encodedQuery&contextLength=$ContextLength"
    Invoke-ObsidianRestMethod -Uri $uri -Method 'POST'
}
