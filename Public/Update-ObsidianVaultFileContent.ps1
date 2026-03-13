function Update-ObsidianVaultFileContent {
    <#
    .SYNOPSIS
        Partially updates a file in the Obsidian vault using PATCH operations.
    .DESCRIPTION
        Inserts content relative to a heading, block reference, or frontmatter field.
    .PARAMETER Path
        Path to the file relative to the vault root.
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
        Update-ObsidianVaultFileContent -Path 'Notes/todo.md' -Operation append -TargetType heading -Target 'Tasks' -Content '- [ ] New task'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

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

    $encodedPath = ConvertTo-ObsidianEncodedPath -Path $Path

    $params = @{
        Uri                  = "/vault/$encodedPath"
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

    if ($PSCmdlet.ShouldProcess("$Path target '$Target'", "PATCH $Operation")) {
        Invoke-ObsidianPatchOperation @params
    }
}
