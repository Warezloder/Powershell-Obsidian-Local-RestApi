function Set-ObsidianVaultFile {
    <#
    .SYNOPSIS
        Creates or replaces a file in the Obsidian vault.
    .DESCRIPTION
        Calls PUT /vault/{filename} to create a new file or replace existing content.
    .PARAMETER Path
        Path to the file relative to the vault root.
    .PARAMETER Content
        The content to write.
    .EXAMPLE
        Set-ObsidianVaultFile -Path 'Notes/new-note.md' -Content '# My New Note'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Content
    )

    if ($PSCmdlet.ShouldProcess($Path, 'Create or replace vault file')) {
        $encodedPath = ConvertTo-ObsidianEncodedPath -Path $Path
        Invoke-ObsidianRestMethod -Uri "/vault/$encodedPath" -Method 'PUT' -Body $Content -ContentType 'text/markdown'
    }
}
