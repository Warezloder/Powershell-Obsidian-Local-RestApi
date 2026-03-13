function Set-ObsidianPeriodicNote {
    <#
    .SYNOPSIS
        Replaces the content of a periodic note.
    .DESCRIPTION
        Calls PUT on the periodic note endpoint to replace its content.
    .PARAMETER Period
        The period type: daily, weekly, monthly, quarterly, or yearly.
    .PARAMETER Content
        The new content for the periodic note.
    .PARAMETER Date
        A specific date. Omit for the current period.
    .EXAMPLE
        Set-ObsidianPeriodicNote -Period daily -Content '# Daily Note'
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [ValidateSet('daily', 'weekly', 'monthly', 'quarterly', 'yearly')]
        [string]$Period = 'daily',

        [Parameter(Mandatory)]
        [string]$Content,

        [Nullable[datetime]]$Date
    )

    $uri = Get-ObsidianPeriodicNoteUri -Period $Period -Date $Date
    $target = if ($null -ne $Date) { "$Period note for $($Date.ToString('yyyy-MM-dd'))" } else { "Current $Period note" }
    if ($PSCmdlet.ShouldProcess($target, 'Replace content')) {
        Invoke-ObsidianRestMethod -Uri $uri -Method 'PUT' -Body $Content -ContentType 'text/markdown'
    }
}
