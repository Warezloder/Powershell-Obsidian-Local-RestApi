function Remove-ObsidianActiveFile {
    <#
    .SYNOPSIS
        Deletes the currently active file in Obsidian.
    .DESCRIPTION
        Calls DELETE /active/ to remove the file that is currently open.
    .EXAMPLE
        Remove-ObsidianActiveFile
    .EXAMPLE
        Remove-ObsidianActiveFile -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param()

    if ($PSCmdlet.ShouldProcess('Active file', 'Delete')) {
        Invoke-ObsidianRestMethod -Uri '/active/' -Method 'DELETE'
    }
}
