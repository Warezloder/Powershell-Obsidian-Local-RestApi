function Update-ObsidianActiveFileContent {
    <#
    .SYNOPSIS
        Partially updates the currently active file using PATCH operations.
    .DESCRIPTION
        Inserts content relative to a heading, block reference, or frontmatter field
        in the currently active file.
    .PARAMETER Operation
        The patch operation: append, prepend, or replace.
    .PARAMETER TargetType
        The type of target: heading, block, or frontmatter.
    .PARAMETER Target
        The target identifier (heading path, block reference, or frontmatter field name).
    .PARAMETER Content
        The content to insert.
    .PARAMETER TargetDelimiter
        Delimiter for nested heading targets. Defaults to '::'.
    .PARAMETER TrimTargetWhitespace
        Whether to trim whitespace from the target before matching.
    .PARAMETER ContentType
        Content type of the body: text/markdown (default) or application/json.
    .PARAMETER CreateTargetIfMissing
        If specified, creates the target if it does not exist (useful for frontmatter fields).
    .EXAMPLE
        Update-ObsidianActiveFileContent -Operation append -TargetType heading -Target 'Heading 1::Subheading' -Content 'New text'
    .EXAMPLE
        Update-ObsidianActiveFileContent -Operation replace -TargetType frontmatter -Target 'status' -Content '"done"' -ContentType 'application/json' -CreateTargetIfMissing
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
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

    $params = @{
        Uri                  = '/active/'
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

    if ($PSCmdlet.ShouldProcess("Active file target '$Target'", "PATCH $Operation")) {
        Invoke-ObsidianPatchOperation @params
    }
}
