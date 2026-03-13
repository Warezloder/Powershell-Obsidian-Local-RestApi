function Set-ObsidianActiveFile {
    <#
    .SYNOPSIS
        Replaces the content of the currently active file in Obsidian.
    .DESCRIPTION
        Calls PUT /active/ with the provided content.
    .PARAMETER Content
        The new content for the active file.
    .EXAMPLE
        Set-ObsidianActiveFile -Content '# New Content'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    if ($PSCmdlet.ShouldProcess('Active file', 'Replace content')) {
        Invoke-ObsidianRestMethod -Uri '/active/' -Method 'PUT' -Body $Content -ContentType 'text/markdown'
    }
}
