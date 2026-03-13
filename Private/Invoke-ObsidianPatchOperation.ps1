function Invoke-ObsidianPatchOperation {
    <#
    .SYNOPSIS
        Shared PATCH operation helper for Active File, Vault Files, and Periodic Notes.
    .DESCRIPTION
        Builds the PATCH request with Operation, Target-Type, Target, and optional
        Target-Delimiter and Trim-Target-Whitespace headers. Used by all three
        Update-Obsidian*Content public functions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

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

    $headers = @{
        'Operation'              = $Operation
        'Target-Type'            = $TargetType
        'Target'                 = $Target
        'Target-Delimiter'       = $TargetDelimiter
        'Trim-Target-Whitespace' = $TrimTargetWhitespace
    }

    if ($CreateTargetIfMissing) {
        $headers['Create-Target-If-Missing'] = 'true'
    }

    Invoke-ObsidianRestMethod -Uri $Uri -Method 'PATCH' -Headers $headers -Body $Content -ContentType $ContentType
}
