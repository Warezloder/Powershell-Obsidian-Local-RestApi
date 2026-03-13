function Remove-ObsidianPeriodicNote {
    <#
    .SYNOPSIS
        Deletes a periodic note.
    .DESCRIPTION
        Calls DELETE on the periodic note endpoint to remove the note.
    .PARAMETER Period
        The period type: daily, weekly, monthly, quarterly, or yearly.
    .PARAMETER Date
        A specific date. Omit for the current period.
    .EXAMPLE
        Remove-ObsidianPeriodicNote -Period daily
    .EXAMPLE
        Remove-ObsidianPeriodicNote -Period weekly -Date (Get-Date '2025-01-15')
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        [ValidateSet('daily', 'weekly', 'monthly', 'quarterly', 'yearly')]
        [string]$Period = 'daily',

        [Nullable[datetime]]$Date
    )

    $uri = Get-ObsidianPeriodicNoteUri -Period $Period -Date $Date
    $target = if ($null -ne $Date) { "$Period note for $($Date.ToString('yyyy-MM-dd'))" } else { "Current $Period note" }

    if ($PSCmdlet.ShouldProcess($target, 'Delete periodic note')) {
        Invoke-ObsidianRestMethod -Uri $uri -Method 'DELETE'
    }
}
