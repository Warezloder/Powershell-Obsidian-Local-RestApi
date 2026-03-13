function Get-ObsidianPeriodicNoteUri {
    <#
    .SYNOPSIS
        Builds the URI for periodic note endpoints.
    .DESCRIPTION
        Returns /periodic/{period}/ for current notes or
        /periodic/{period}/{year}/{month}/{day}/ for dated notes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Period,

        [Parameter()]
        [Nullable[datetime]]$Date
    )

    if ($null -ne $Date) {
        '/periodic/{0}/{1}/{2}/{3}/' -f $Period, $Date.Year, $Date.Month, $Date.Day
    }
    else {
        '/periodic/{0}/' -f $Period
    }
}
