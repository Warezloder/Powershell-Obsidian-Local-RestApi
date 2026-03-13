function Get-ObsidianCommand {
    <#
    .SYNOPSIS
        Gets a list of available Obsidian commands.
    .DESCRIPTION
        Calls GET /commands/ to retrieve all registered commands.
        Optionally filters by name using wildcard matching.
    .PARAMETER Name
        Filter commands by name using wildcard patterns.
    .EXAMPLE
        Get-ObsidianCommand
    .EXAMPLE
        Get-ObsidianCommand -Name '*search*'
    #>
    [CmdletBinding()]
    param(
        [string]$Name
    )

    $result = Invoke-ObsidianRestMethod -Uri '/commands/'
    $commands = $result.commands

    if ($Name) {
        $commands = $commands | Where-Object { $_.name -like $Name }
    }

    $commands
}
