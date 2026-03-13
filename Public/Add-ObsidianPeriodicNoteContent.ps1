function Add-ObsidianPeriodicNoteContent {
    <#
    .SYNOPSIS
        Appends content to a periodic note.
    .DESCRIPTION
        Calls POST on the periodic note endpoint. Creates the note if it does not exist.
    .PARAMETER Period
        The period type: daily, weekly, monthly, quarterly, or yearly.
    .PARAMETER Content
        The content to append.
    .PARAMETER Date
        A specific date. Omit for the current period.
    .EXAMPLE
        Add-ObsidianPeriodicNoteContent -Period daily -Content "`n- Meeting at 3pm"
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('daily', 'weekly', 'monthly', 'quarterly', 'yearly')]
        [string]$Period = 'daily',

        [Parameter(Mandatory)]
        [string]$Content,

        [Nullable[datetime]]$Date
    )

    $uri = Get-ObsidianPeriodicNoteUri -Period $Period -Date $Date
    Invoke-ObsidianRestMethod -Uri $uri -Method 'POST' -Body $Content -ContentType 'text/markdown'
}
