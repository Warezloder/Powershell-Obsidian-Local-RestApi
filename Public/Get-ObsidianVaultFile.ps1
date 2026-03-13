function Get-ObsidianVaultFile {
    <#
    .SYNOPSIS
        Returns the content of a file in the Obsidian vault.
    .DESCRIPTION
        Calls GET /vault/{filename} with the specified format.
    .PARAMETER Path
        Path to the file relative to the vault root.
    .PARAMETER Format
        The response format: Markdown (default), Json, or DocumentMap.
    .EXAMPLE
        Get-ObsidianVaultFile -Path 'Notes/my-note.md'
    .EXAMPLE
        Get-ObsidianVaultFile -Path 'Notes/my-note.md' -Format Json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('Markdown', 'Json', 'DocumentMap')]
        [string]$Format = 'Markdown'
    )

    $encodedPath = ConvertTo-ObsidianEncodedPath -Path $Path
    $accept = $script:FormatToAcceptHeader[$Format]
    Invoke-ObsidianRestMethod -Uri "/vault/$encodedPath" -Accept $accept
}
