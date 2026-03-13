# Module-scoped variables
$script:ApiKey = $null
$script:BaseUrl = $null
$script:SkipCertCheck = $true

# Format-to-Accept header mapping
$script:FormatToAcceptHeader = @{
    'Markdown'    = 'text/markdown'
    'Json'        = 'application/vnd.olrapi.note+json'
    'DocumentMap' = 'application/vnd.olrapi.document-map+json'
}

# Dot-source private functions
foreach ($file in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -ErrorAction SilentlyContinue) {
    . $file.FullName
}

# Dot-source public functions
foreach ($file in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -ErrorAction SilentlyContinue) {
    . $file.FullName
}
