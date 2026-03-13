function Remove-ObsidianVaultFile {
    <#
    .SYNOPSIS
        Deletes a file from the Obsidian vault.
    .DESCRIPTION
        Calls DELETE /vault/{filename} to remove the specified file.
    .PARAMETER Path
        Path to the file relative to the vault root.
    .EXAMPLE
        Remove-ObsidianVaultFile -Path 'Notes/old-note.md'
    .EXAMPLE
        Remove-ObsidianVaultFile -Path 'Notes/old-note.md' -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if ($PSCmdlet.ShouldProcess($Path, 'Delete vault file')) {
        $encodedPath = ConvertTo-ObsidianEncodedPath -Path $Path
        Invoke-ObsidianRestMethod -Uri "/vault/$encodedPath" -Method 'DELETE'
    }
}
