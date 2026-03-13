function Open-ObsidianFile {
    <#
    .SYNOPSIS
        Opens a file in the Obsidian user interface.
    .DESCRIPTION
        Calls POST /open/{filename} to open the specified file in Obsidian.
        Creates the file if it does not already exist.
    .PARAMETER Path
        Path to the file relative to the vault root.
    .PARAMETER NewLeaf
        If specified, opens the file in a new leaf (tab/pane).
    .EXAMPLE
        Open-ObsidianFile -Path 'Notes/my-note.md'
    .EXAMPLE
        Open-ObsidianFile -Path 'Notes/my-note.md' -NewLeaf
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$NewLeaf
    )

    $encodedPath = ConvertTo-ObsidianEncodedPath -Path $Path
    $uri = "/open/$encodedPath"
    if ($NewLeaf) {
        $uri += '?newLeaf=true'
    }
    Invoke-ObsidianRestMethod -Uri $uri -Method 'POST'
}
