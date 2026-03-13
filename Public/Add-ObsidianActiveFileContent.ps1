function Add-ObsidianActiveFileContent {
    <#
    .SYNOPSIS
        Appends content to the currently active file in Obsidian.
    .DESCRIPTION
        Calls POST /active/ to append content to the end of the active file.
    .PARAMETER Content
        The content to append.
    .EXAMPLE
        Add-ObsidianActiveFileContent -Content "`n## New Section`nSome text here."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )

    Invoke-ObsidianRestMethod -Uri '/active/' -Method 'POST' -Body $Content -ContentType 'text/markdown'
}
