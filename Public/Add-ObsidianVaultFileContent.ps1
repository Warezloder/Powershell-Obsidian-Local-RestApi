function Add-ObsidianVaultFileContent {
    <#
    .SYNOPSIS
        Appends content to a file in the Obsidian vault.
    .DESCRIPTION
        Calls POST /vault/{filename} to append content. Creates an empty file if it does not exist.
    .PARAMETER Path
        Path to the file relative to the vault root.
    .PARAMETER Content
        The content to append.
    .EXAMPLE
        Add-ObsidianVaultFileContent -Path 'Notes/log.md' -Content "`n- New entry"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $encodedPath = ConvertTo-ObsidianEncodedPath -Path $Path
    Invoke-ObsidianRestMethod -Uri "/vault/$encodedPath" -Method 'POST' -Body $Content -ContentType 'text/markdown'
}
