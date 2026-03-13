function Get-ObsidianVaultDirectory {
    <#
    .SYNOPSIS
        Lists files and directories in the Obsidian vault.
    .DESCRIPTION
        Calls GET /vault/ (root) or GET /vault/{pathToDirectory}/ to list contents.
        Directories in the results end with '/'.
    .PARAMETER Path
        Path to the directory relative to the vault root. Omit to list the vault root.
    .EXAMPLE
        Get-ObsidianVaultDirectory
    .EXAMPLE
        Get-ObsidianVaultDirectory -Path 'Notes'
    #>
    [CmdletBinding()]
    param(
        [string]$Path
    )

    if ($Path) {
        $encodedPath = ConvertTo-ObsidianEncodedPath -Path $Path
        $uri = "/vault/$encodedPath/"
    }
    else {
        $uri = '/vault/'
    }

    $result = Invoke-ObsidianRestMethod -Uri $uri
    $result.files
}
