function Get-ObsidianPeriodicNote {
    <#
    .SYNOPSIS
        Gets a periodic note from the Obsidian vault.
    .DESCRIPTION
        Retrieves the current or dated periodic note for the specified period.
        Without -Date, returns the current period's note.
        With -Date, returns the note for that specific date.
    .PARAMETER Period
        The period type: daily, weekly, monthly, quarterly, or yearly.
    .PARAMETER Date
        A specific date to retrieve the periodic note for. Omit for the current period.
    .PARAMETER Format
        The response format: Markdown (default), Json, or DocumentMap.
    .EXAMPLE
        Get-ObsidianPeriodicNote -Period daily
    .EXAMPLE
        Get-ObsidianPeriodicNote -Period weekly -Date (Get-Date '2025-01-15')
    .EXAMPLE
        Get-ObsidianPeriodicNote -Period daily -Format Json
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('daily', 'weekly', 'monthly', 'quarterly', 'yearly')]
        [string]$Period = 'daily',

        [Nullable[datetime]]$Date,

        [ValidateSet('Markdown', 'Json', 'DocumentMap')]
        [string]$Format = 'Markdown'
    )

    $uri = Get-ObsidianPeriodicNoteUri -Period $Period -Date $Date
    $accept = $script:FormatToAcceptHeader[$Format]
    Invoke-ObsidianRestMethod -Uri $uri -Accept $accept
}
