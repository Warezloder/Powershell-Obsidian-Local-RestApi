function Invoke-ObsidianRestMethod {
    <#
    .SYNOPSIS
        Central wrapper for all Obsidian Local REST API calls.
    .DESCRIPTION
        Handles auth header injection, base URL construction, self-signed certificate bypass,
        and error response parsing for all API endpoints.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [ValidateSet('GET', 'PUT', 'POST', 'PATCH', 'DELETE')]
        [string]$Method = 'GET',

        [hashtable]$Headers = @{},

        [object]$Body,

        [string]$ContentType,

        [string]$Accept
    )

    if (-not $script:BaseUrl) {
        throw 'Not connected to Obsidian API. Run Connect-ObsidianApi first.'
    }

    $fullUri = '{0}{1}' -f $script:BaseUrl, $Uri

    if ($script:ApiKey) {
        $Headers['Authorization'] = "Bearer $($script:ApiKey)"
    }

    if ($Accept) {
        $Headers['Accept'] = $Accept
    }

    $params = @{
        Uri                  = $fullUri
        Method               = $Method
        Headers              = $Headers
        SkipCertificateCheck = $script:SkipCertCheck
        ErrorAction          = 'Stop'
    }

    if ($null -ne $Body) {
        $params['Body'] = $Body
    }
    if ($ContentType) {
        $params['ContentType'] = $ContentType
    }

    try {
        Invoke-RestMethod @params
    }
    catch {
        $statusCode = $null
        $errorBody = $null

        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        # In PowerShell 7, the response body is captured in ErrorDetails.Message
        if ($_.ErrorDetails.Message) {
            try {
                $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
            }
            catch {
                Write-Verbose "Could not parse API error response body as JSON."
            }
        }

        if ($errorBody -and $errorBody.message) {
            $msg = "Obsidian API error ($statusCode): $($errorBody.message)"
            if ($errorBody.errorCode) {
                $msg += " [Code: $($errorBody.errorCode)]"
            }
            throw $msg
        }

        throw $_
    }
}
