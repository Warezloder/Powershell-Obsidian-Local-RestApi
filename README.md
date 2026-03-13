# ObsidianLocalRestApi

PowerShell module for the [Obsidian Local REST API](https://github.com/coddingtonbear/obsidian-local-rest-api) plugin. Wraps every REST endpoint with proper authentication, self-signed certificate handling, and consistent error reporting. You can automate your Obsidian vault from any PowerShell script or pipeline.

## Features

- Single connection command stores credentials for the session, no token plumbing in every call
- Full coverage: System, Commands, Active File, Vault Files, Vault Directories, Periodic Notes, Search, and Open endpoints
- Three response formats for file reads: raw Markdown, structured JSON (with frontmatter, tags, stat), and DocumentMap (headings and blocks)
- Surgical PATCH operations. Append, prepend, or replace content at a specific heading, block reference, or frontmatter field
- ShouldProcess / -WhatIf / -Confirm support on all destructive and write commands
- Self-signed certificate bypass enabled automatically for localhost connections
- Windows backslash paths accepted everywhere. Normalized to forward slashes internally

## Requirements

- PowerShell 7.0 or higher
- [Obsidian](https://obsidian.md) desktop application with the [Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) installed and enabled

## Platform Support

| Platform | Status       |
|----------|--------------|
| Windows  | Supported    |
| Linux    | Supported    |
| macOS    | Supported    |

## Installation

### From PowerShell Gallery (when published)

```powershell
# Issues with accessing PowershellGallery User Account at this moment. I will Publish soon...
Install-Module -Name ObsidianLocalRestApi -Scope CurrentUser
```

### Manual Installation

```powershell
# Determine a suitable module directory (first entry in PSModulePath)
$modulesRoot = ($env:PSModulePath -split [IO.Path]::PathSeparator)[0]
$destination = Join-Path -Path $modulesRoot -ChildPath 'ObsidianLocalRestApi'

Copy-Item -Path '.\ObsidianLocalRestApi' -Destination $destination -Recurse

# Verify
Get-Module -Name ObsidianLocalRestApi -ListAvailable
```

### Import Directly (no install required)

```powershell
Import-Module '.\output\ObsidianLocalRestApi'
```

## Quick Start

**Step 1 — Enable the plugin.** In Obsidian: Settings > Community plugins > Local REST API. Copy the API key shown there.

**Step 2 — Connect.**

```powershell
Import-Module ObsidianLocalRestApi

Connect-ObsidianApi -ApiKey 'your-api-key-here'
```

**Step 3 — Use the vault.**

```powershell
# Read the currently open file
Get-ObsidianActiveFile

# List vault root
Get-ObsidianVaultDirectory

# Write a new note
Set-ObsidianVaultFile -Path 'Inbox/quick-thought.md' -Content "# Quick Thought`n`nCapture this idea."

# Append to today's daily note
Add-ObsidianPeriodicNoteContent -Period daily -Content "`n- Finished the PowerShell module docs"

# Search
Search-ObsidianVaultSimple -Query 'project alpha'
```

**Step 4 — Disconnect when done.**

```powershell
Disconnect-ObsidianApi
```

## Functions

| Function | Description |
|----------|-------------|
| `Connect-ObsidianApi` | Authenticate and store credentials for the session |
| `Disconnect-ObsidianApi` | Clear stored credentials |
| `Get-ObsidianServerStatus` | Server version and authentication state |
| `Get-ObsidianApiCertificate` | Download the self-signed TLS certificate |
| `Get-ObsidianApiSpec` | Download the OpenAPI YAML specification |
| `Get-ObsidianCommand` | List available Obsidian commands (supports wildcard filter) |
| `Invoke-ObsidianCommand` | Execute a command by ID; accepts pipeline from Get-ObsidianCommand |
| `Get-ObsidianActiveFile` | Read the currently open file (Markdown / Json / DocumentMap) |
| `Set-ObsidianActiveFile` | Replace the active file's content |
| `Add-ObsidianActiveFileContent` | Append content to the active file |
| `Update-ObsidianActiveFileContent` | PATCH the active file at a heading, block, or frontmatter field |
| `Remove-ObsidianActiveFile` | Delete the active file |
| `Get-ObsidianVaultFile` | Read any vault file by path |
| `Set-ObsidianVaultFile` | Create or replace a vault file |
| `Add-ObsidianVaultFileContent` | Append content to a vault file |
| `Update-ObsidianVaultFileContent` | PATCH a vault file at a heading, block, or frontmatter field |
| `Remove-ObsidianVaultFile` | Delete a vault file |
| `Get-ObsidianVaultDirectory` | List files and subdirectories in a vault directory |
| `Get-ObsidianPeriodicNote` | Read a periodic note (daily/weekly/monthly/quarterly/yearly) |
| `Set-ObsidianPeriodicNote` | Replace a periodic note's content |
| `Add-ObsidianPeriodicNoteContent` | Append content to a periodic note |
| `Update-ObsidianPeriodicNoteContent` | PATCH a periodic note at a heading, block, or frontmatter field |
| `Remove-ObsidianPeriodicNote` | Delete a periodic note |
| `Search-ObsidianVault` | Search with JsonLogic or Dataview DQL |
| `Search-ObsidianVaultSimple` | Full-text search with surrounding context |
| `Open-ObsidianFile` | Open a file in the Obsidian UI |

## Examples

### Securely store and reuse the API key

```powershell
# Save (one time)
Read-Host -Prompt 'Obsidian API key' -AsSecureString |
    Export-Clixml -Path (Join-Path $HOME '.obsidian-key.xml')

# Load in future sessions
$key = Import-Clixml -Path (Join-Path $HOME '.obsidian-key.xml') |
    ConvertFrom-SecureString -AsPlainText
Connect-ObsidianApi -ApiKey $key
```

### Bulk-create notes from a CSV

```powershell
Import-Csv -Path (Join-Path $PSScriptRoot 'notes.csv') | ForEach-Object {
    Set-ObsidianVaultFile -Path "Projects/$($_.Name).md" -Content "# $($_.Name)`n`n$($_.Body)"
}
```

### Update a frontmatter field

```powershell
Update-ObsidianVaultFileContent `
    -Path 'Projects/alpha.md' `
    -Operation replace `
    -TargetType frontmatter `
    -Target 'status' `
    -Content '"complete"' `
    -ContentType 'application/json' `
    -CreateTargetIfMissing
```

### Run a command from the palette

```powershell
Get-ObsidianCommand -Name '*graph*' | Invoke-ObsidianCommand
```

## License

(c) 2026. All rights reserved.
