function Get-ObsidianActiveFile {
    <#
    .SYNOPSIS
        Returns the content of the currently active file in Obsidian.
    .DESCRIPTION
        Calls GET /active/ with the specified format.
        Markdown returns raw text, Json returns a NoteJson object with
        content, frontmatter, path, stat, and tags. DocumentMap returns
        headings, blocks, and frontmatterFields arrays.
    .PARAMETER Format
        The response format: Markdown (default), Json, or DocumentMap.
    .EXAMPLE
        Get-ObsidianActiveFile
    .EXAMPLE
        Get-ObsidianActiveFile -Format Json
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Markdown', 'Json', 'DocumentMap')]
        [string]$Format = 'Markdown'
    )

    $accept = $script:FormatToAcceptHeader[$Format]
    Invoke-ObsidianRestMethod -Uri '/active/' -Accept $accept
}
