@{
    RootModule        = 'ObsidianLocalRestApi.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'a3f7b2c1-4d5e-6f8a-9b0c-1d2e3f4a5b6c'
    Author            = 'PowerShell Forge'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026. All rights reserved.'
    Description       = 'PowerShell module for the Obsidian Local REST API plugin. Wraps all REST endpoints (System, Active File, Commands, Vault Files, Vault Directories, Periodic Notes, Search, Open) with proper auth, self-signed cert handling, and shared PATCH helper pattern.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Connect-ObsidianApi'
        'Disconnect-ObsidianApi'
        'Get-ObsidianServerStatus'
        'Get-ObsidianApiCertificate'
        'Get-ObsidianApiSpec'
        'Get-ObsidianCommand'
        'Invoke-ObsidianCommand'
        'Get-ObsidianActiveFile'
        'Set-ObsidianActiveFile'
        'Add-ObsidianActiveFileContent'
        'Update-ObsidianActiveFileContent'
        'Remove-ObsidianActiveFile'
        'Get-ObsidianVaultFile'
        'Set-ObsidianVaultFile'
        'Add-ObsidianVaultFileContent'
        'Update-ObsidianVaultFileContent'
        'Remove-ObsidianVaultFile'
        'Get-ObsidianVaultDirectory'
        'Get-ObsidianPeriodicNote'
        'Set-ObsidianPeriodicNote'
        'Add-ObsidianPeriodicNoteContent'
        'Update-ObsidianPeriodicNoteContent'
        'Remove-ObsidianPeriodicNote'
        'Search-ObsidianVault'
        'Search-ObsidianVaultSimple'
        'Open-ObsidianFile'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('Obsidian', 'REST', 'API', 'Markdown', 'Notes', 'Vault')
            ProjectUri = 'https://github.com/coddingtonbear/obsidian-local-rest-api'
        }
    }
}
