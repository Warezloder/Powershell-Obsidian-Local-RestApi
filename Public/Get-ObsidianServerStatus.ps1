function Get-ObsidianServerStatus {
    <#
    .SYNOPSIS
        Returns basic details about the Obsidian Local REST API server.
    .DESCRIPTION
        Calls GET / which returns server status, authentication state, and version info.
        This is the only endpoint that does not require authentication.
    .EXAMPLE
        Get-ObsidianServerStatus
    #>
    [CmdletBinding()]
    param()

    Invoke-ObsidianRestMethod -Uri '/'
}
