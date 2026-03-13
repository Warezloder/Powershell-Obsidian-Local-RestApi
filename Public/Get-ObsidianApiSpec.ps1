function Get-ObsidianApiSpec {
    <#
    .SYNOPSIS
        Returns the OpenAPI YAML specification for the Obsidian Local REST API.
    .DESCRIPTION
        Downloads the OpenAPI spec from GET /openapi.yaml.
        Optionally saves it to a file.
    .PARAMETER OutFile
        Path to save the YAML file.
    .EXAMPLE
        Get-ObsidianApiSpec
    .EXAMPLE
        Get-ObsidianApiSpec -OutFile .\openapi.yaml
    #>
    [CmdletBinding()]
    param(
        [string]$OutFile
    )

    $spec = Invoke-ObsidianRestMethod -Uri '/openapi.yaml'

    if ($OutFile) {
        $spec | Set-Content -Path $OutFile -NoNewline -Encoding utf8NoBOM
        Write-Verbose "OpenAPI spec saved to $OutFile"
    }
    else {
        $spec
    }
}
