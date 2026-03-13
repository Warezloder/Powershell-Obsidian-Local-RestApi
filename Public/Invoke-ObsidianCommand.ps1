function Invoke-ObsidianCommand {
    <#
    .SYNOPSIS
        Executes an Obsidian command by its ID.
    .DESCRIPTION
        Calls POST /commands/{commandId}/ to execute the specified command.
    .PARAMETER CommandId
        The ID of the command to execute.
    .EXAMPLE
        Invoke-ObsidianCommand -CommandId 'global-search:open'
    .EXAMPLE
        Get-ObsidianCommand -Name '*graph*' | Invoke-ObsidianCommand
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('id')]
        [string]$CommandId
    )

    process {
        $encodedId = [uri]::EscapeDataString($CommandId)
        Invoke-ObsidianRestMethod -Uri "/commands/$encodedId/" -Method 'POST'
    }
}
