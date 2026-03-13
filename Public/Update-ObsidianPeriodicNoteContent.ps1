function Update-ObsidianPeriodicNoteContent {
    <#
    .SYNOPSIS
        Partially updates a periodic note using PATCH operations.
    .DESCRIPTION
        Inserts content relative to a heading, block reference, or frontmatter field.
    .PARAMETER Period
        The period type: daily, weekly, monthly, quarterly, or yearly.
    .PARAMETER Date
        A specific date. Omit for the current period.
    .PARAMETER Operation
        The patch operation: append, prepend, or replace.
    .PARAMETER TargetType
        The type of target: heading, block, or frontmatter.
    .PARAMETER Target
        The target identifier.
    .PARAMETER Content
        The content to insert.
    .PARAMETER TargetDelimiter
        Delimiter for nested heading targets. Defaults to '::'.
    .PARAMETER TrimTargetWhitespace
        Whether to trim whitespace from the target before matching.
    .PARAMETER ContentType
        Content type of the body: text/markdown (default) or application/json.
    .PARAMETER CreateTargetIfMissing
        If specified, creates the target if it does not exist.
    .EXAMPLE
        Update-ObsidianPeriodicNoteContent -Period daily -Operation append -TargetType heading -Target 'Tasks' -Content '- [ ] New task'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('daily', 'weekly', 'monthly', 'quarterly', 'yearly')]
        [string]$Period = 'daily',

        [Nullable[datetime]]$Date,

        [Parameter(Mandatory)]
        [ValidateSet('append', 'prepend', 'replace')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [ValidateSet('heading', 'block', 'frontmatter')]
        [string]$TargetType,

        [Parameter(Mandatory)]
        [string]$Target,

        [Parameter(Mandatory)]
        [string]$Content,

        [string]$TargetDelimiter = '::',

        [ValidateSet('true', 'false')]
        [string]$TrimTargetWhitespace = 'false',

        [ValidateSet('text/markdown', 'application/json')]
        [string]$ContentType = 'text/markdown',

        [switch]$CreateTargetIfMissing
    )

    $uri = Get-ObsidianPeriodicNoteUri -Period $Period -Date $Date

    $params = @{
        Uri                  = $uri
        Operation            = $Operation
        TargetType           = $TargetType
        Target               = $Target
        Content              = $Content
        TargetDelimiter      = $TargetDelimiter
        TrimTargetWhitespace = $TrimTargetWhitespace
        ContentType          = $ContentType
    }
    if ($CreateTargetIfMissing) {
        $params['CreateTargetIfMissing'] = $true
    }

    if ($PSCmdlet.ShouldProcess("$Period note target '$Target'", "PATCH $Operation")) {
        Invoke-ObsidianPatchOperation @params
    }
}
