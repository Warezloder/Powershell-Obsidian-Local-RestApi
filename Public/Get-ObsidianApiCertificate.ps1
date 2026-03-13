function Get-ObsidianApiCertificate {
    <#
    .SYNOPSIS
        Returns the self-signed certificate used by the Obsidian Local REST API.
    .DESCRIPTION
        Downloads the certificate from GET /obsidian-local-rest-api.crt.
        Optionally saves it to a file.
    .PARAMETER OutFile
        Path to save the certificate file.
    .EXAMPLE
        Get-ObsidianApiCertificate
    .EXAMPLE
        Get-ObsidianApiCertificate -OutFile .\obsidian.crt
    #>
    [CmdletBinding()]
    param(
        [string]$OutFile
    )

    $cert = Invoke-ObsidianRestMethod -Uri '/obsidian-local-rest-api.crt'

    if ($OutFile) {
        $cert | Set-Content -Path $OutFile -NoNewline -Encoding utf8NoBOM
        Write-Verbose "Certificate saved to $OutFile"
    }
    else {
        $cert
    }
}
