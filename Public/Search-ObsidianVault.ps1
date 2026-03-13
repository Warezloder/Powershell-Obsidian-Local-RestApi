function Search-ObsidianVault {
    <#
    .SYNOPSIS
        Searches the Obsidian vault using JsonLogic or Dataview DQL queries.
    .DESCRIPTION
        Calls POST /search/ with the specified query. The query type determines
        the Content-Type header sent to the API.
    .PARAMETER Query
        The search query string (JsonLogic JSON or Dataview DQL).
    .PARAMETER QueryType
        The query format: JsonLogic or DataviewDQL.
    .EXAMPLE
        Search-ObsidianVault -Query '{"in": ["myTag", {"var": "tags"}]}' -QueryType JsonLogic
    .EXAMPLE
        Search-ObsidianVault -Query 'TABLE file.name FROM #project' -QueryType DataviewDQL
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        [ValidateSet('JsonLogic', 'DataviewDQL')]
        [string]$QueryType
    )

    $contentTypeMap = @{
        'JsonLogic'   = 'application/vnd.olrapi.jsonlogic+json'
        'DataviewDQL' = 'application/vnd.olrapi.dataview.dql+txt'
    }

    $contentType = $contentTypeMap[$QueryType]
    Invoke-ObsidianRestMethod -Uri '/search/' -Method 'POST' -Body $Query -ContentType $contentType
}
