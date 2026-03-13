# How to Use ObsidianLocalRestApi

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Platform-Specific Notes](#platform-specific-notes)
4. [Connecting and Disconnecting](#connecting-and-disconnecting)
5. [Common Scenarios](#common-scenarios)
6. [Function Reference](#function-reference)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **PowerShell 7.0 or higher** (cross-platform; `pwsh` binary)
- **Obsidian** desktop application
- **Local REST API plugin** installed and enabled in Obsidian
  - Install via Obsidian: Settings > Community plugins > Browse > search "Local REST API"
  - After enabling, go to the plugin settings to find your API key and the listening port (default `27124`)

---

## Installation

### From PowerShell Gallery (when published)

```powershell
Install-Module -Name ObsidianLocalRestApi -Scope CurrentUser
```

### Manual Installation

```powershell
$modulesRoot = ($env:PSModulePath -split [IO.Path]::PathSeparator)[0]
$destination = Join-Path -Path $modulesRoot -ChildPath 'ObsidianLocalRestApi'
Copy-Item -Path '.\output\ObsidianLocalRestApi' -Destination $destination -Recurse
```

### Import Without Installing

```powershell
Import-Module '.\output\ObsidianLocalRestApi'
```

---

## Platform-Specific Notes

### Windows

- Compatible with both PowerShell 7+ (`pwsh`) and Windows PowerShell 5.1 is **not** supported — use `pwsh`.
- If scripts are blocked by execution policy, run once:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
- Both backslash (`Notes\my-note.md`) and forward-slash (`Notes/my-note.md`) vault paths are accepted. The module normalizes them internally.

### Linux

- Requires `pwsh` (PowerShell 7+). Install via your package manager or the [official Microsoft instructions](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux).
- Vault file paths are case-sensitive on the API side — match the exact casing used in Obsidian.
- The Obsidian desktop app must be running on the same machine (or be network-accessible with a custom `BaseUrl`).

### macOS

- Requires `pwsh` (PowerShell 7+). Install via Homebrew: `brew install --cask powershell`.
- Vault file paths are case-sensitive — use the exact casing.
- The default `https://127.0.0.1:27124` works when Obsidian is running locally.

---

## Connecting and Disconnecting

### Connect-ObsidianApi

Every function in this module requires an active session. Call `Connect-ObsidianApi` once at the start of your script or session.

**Basic connection (localhost defaults)**

```powershell
Connect-ObsidianApi -ApiKey 'your-api-key-here'
```

`Connect-ObsidianApi` calls the server status endpoint immediately to validate the key. If authentication fails, the credentials are discarded and an error is thrown. On success it returns the status object (service name, plugin version, Obsidian API version).

**Custom host or port**

```powershell
Connect-ObsidianApi -ApiKey $key -BaseUrl 'https://192.168.1.50:27124' -SkipCertificateCheck
```

When `BaseUrl` points to a non-localhost address, certificate checking is enabled by default. Pass `-SkipCertificateCheck` if using a self-signed certificate on a remote host.

**Storing the key securely**

```powershell
# Save once — prompts for the key interactively
Read-Host -Prompt 'API key' -AsSecureString |
    Export-Clixml -Path (Join-Path $HOME '.obsidian-key.xml')

# Load in scripts (never hard-code keys in files)
$key = Import-Clixml -Path (Join-Path $HOME '.obsidian-key.xml') |
    ConvertFrom-SecureString -AsPlainText
Connect-ObsidianApi -ApiKey $key
```

### Disconnect-ObsidianApi

Clears the API key and base URL from module memory. Call this at the end of automation scripts or before switching vaults.

```powershell
Disconnect-ObsidianApi
```

---

## Common Scenarios

### Scenario 1: Daily journaling automation

Append a timestamped entry to today's daily note.

```powershell
Connect-ObsidianApi -ApiKey $key

$timestamp = (Get-Date).ToString('HH:mm')
$entry = "`n- [$timestamp] Automated check-in: all systems nominal"
Add-ObsidianPeriodicNoteContent -Period daily -Content $entry
```

### Scenario 2: Read and process the active file's frontmatter

Use the `Json` format to get structured data including frontmatter, tags, and file stat.

```powershell
$note = Get-ObsidianActiveFile -Format Json

# Inspect frontmatter
$note.frontmatter

# Check tags
$note.tags

# File path inside the vault
$note.path
```

### Scenario 3: Bulk-create notes from a data source

```powershell
$items = Import-Csv -Path (Join-Path $PSScriptRoot 'projects.csv')

foreach ($item in $items) {
    $content = @"
---
status: active
owner: $($item.Owner)
---
# $($item.Name)

$($item.Description)
"@
    Set-ObsidianVaultFile -Path "Projects/$($item.Name).md" -Content $content
    Write-Host "Created Projects/$($item.Name).md"
}
```

### Scenario 4: Update a frontmatter field across multiple notes

```powershell
$filesToUpdate = @(
    'Projects/alpha.md',
    'Projects/beta.md',
    'Projects/gamma.md'
)

foreach ($path in $filesToUpdate) {
    Update-ObsidianVaultFileContent `
        -Path $path `
        -Operation replace `
        -TargetType frontmatter `
        -Target 'status' `
        -Content '"archived"' `
        -ContentType 'application/json' `
        -CreateTargetIfMissing
}
```

### Scenario 5: Append a task under a specific heading

```powershell
$task = "- [ ] Review pull request #$(Get-Random -Minimum 100 -Maximum 999)"

Update-ObsidianVaultFileContent `
    -Path 'Work/sprint.md' `
    -Operation append `
    -TargetType heading `
    -Target 'This Week::Tasks' `
    -Content $task
```

The `Target` uses `::` as the default delimiter for nested headings. "This Week::Tasks" targets the `## Tasks` heading inside the `## This Week` section.

### Scenario 6: Search and open results

```powershell
# Find notes mentioning a topic
$results = Search-ObsidianVaultSimple -Query 'quarterly review' -ContextLength 200

$results | ForEach-Object {
    Write-Host "--- $($_.filename) ---"
    $_.matches | ForEach-Object { Write-Host "  $($_.context)" }
}

# Open the first result in Obsidian
if ($results.Count -gt 0) {
    Open-ObsidianFile -Path $results[0].filename -NewLeaf
}
```

### Scenario 7: Execute Obsidian commands

```powershell
# List all commands whose names contain 'template'
Get-ObsidianCommand -Name '*template*'

# Execute a specific command by ID
Invoke-ObsidianCommand -CommandId 'templater-obsidian:insert-templater-file-template'

# Pipeline: run every command matching a pattern
Get-ObsidianCommand -Name '*graph*' | Invoke-ObsidianCommand
```

### Scenario 8: Working with periodic notes by date

```powershell
# Read last Monday's daily note
$lastMonday = (Get-Date).AddDays(-((Get-Date).DayOfWeek - [DayOfWeek]::Monday))
Get-ObsidianPeriodicNote -Period daily -Date $lastMonday

# Append to a specific weekly note
Add-ObsidianPeriodicNoteContent `
    -Period weekly `
    -Date (Get-Date '2026-01-12') `
    -Content "`n- Retrospective item added retroactively"
```

### Scenario 9: Export the API certificate for trusted connections

```powershell
# Save the certificate for use with -SkipCertificateCheck:$false
Get-ObsidianApiCertificate -OutFile (Join-Path $HOME 'obsidian-local-rest-api.crt')
```

After exporting, you can add the certificate to your system's trust store so connections work without `-SkipCertificateCheck`.

### Scenario 10: WhatIf support on destructive operations

All write and delete functions support `-WhatIf` and `-Confirm`.

```powershell
# Preview what would be deleted without actually deleting
Remove-ObsidianVaultFile -Path 'Archive/old-note.md' -WhatIf

# Suppress confirmation prompt on high-impact operations
Remove-ObsidianActiveFile -Confirm:$false
```

---

## Function Reference

### Connect-ObsidianApi

Authenticates with the Obsidian Local REST API and stores credentials in module scope for the duration of the session.

**Syntax**
```powershell
Connect-ObsidianApi -ApiKey <String> [-BaseUrl <String>] [-SkipCertificateCheck]
```

**Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-ApiKey` | String | Yes | - | API key from Obsidian Settings > Local REST API |
| `-BaseUrl` | String | No | `https://127.0.0.1:27124` | Base URL of the REST API |
| `-SkipCertificateCheck` | Switch | No | Auto (true for localhost) | Bypass TLS certificate validation |

**Output:** Server status object with `service`, `versions`, and `authenticated` properties.

---

### Disconnect-ObsidianApi

Clears all stored session credentials from module memory.

**Syntax**
```powershell
Disconnect-ObsidianApi
```

**Output:** None.

---

### Get-ObsidianServerStatus

Returns basic server information. This is the only endpoint that does not require authentication, so it can be called before `Connect-ObsidianApi`.

**Syntax**
```powershell
Get-ObsidianServerStatus
```

**Output:** Object with `service`, `authenticated`, `versions` (containing `self` and `obsidian`).

---

### Get-ObsidianApiCertificate

Downloads the self-signed TLS certificate used by the API server.

**Syntax**
```powershell
Get-ObsidianApiCertificate [-OutFile <String>]
```

**Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-OutFile` | String | No | - | Path to save the `.crt` file. If omitted, returns the certificate text. |

---

### Get-ObsidianApiSpec

Downloads the OpenAPI YAML specification for the API.

**Syntax**
```powershell
Get-ObsidianApiSpec [-OutFile <String>]
```

**Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-OutFile` | String | No | - | Path to save the `.yaml` file. If omitted, returns the YAML as a string. |

---

### Get-ObsidianCommand

Lists all registered Obsidian commands. Each command object has `id` and `name` properties.

**Syntax**
```powershell
Get-ObsidianCommand [-Name <String>]
```

**Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Name` | String | No | - | Wildcard filter applied to the command `name` field |

```powershell
# All commands
Get-ObsidianCommand

# Filter by wildcard
Get-ObsidianCommand -Name '*daily*'
```

---

### Invoke-ObsidianCommand

Executes an Obsidian command. Accepts pipeline input from `Get-ObsidianCommand` via the `id` property alias.

**Syntax**
```powershell
Invoke-ObsidianCommand -CommandId <String>
```

**Parameters**

| Parameter | Type | Required | Pipeline | Description |
|-----------|------|----------|----------|-------------|
| `-CommandId` | String | Yes | Yes (ByPropertyName, alias `id`) | The command ID to execute |

```powershell
Invoke-ObsidianCommand -CommandId 'global-search:open'
Get-ObsidianCommand -Name '*graph*' | Invoke-ObsidianCommand
```

---

### Get-ObsidianActiveFile

Reads the content of the file currently open in Obsidian.

**Syntax**
```powershell
Get-ObsidianActiveFile [-Format <String>]
```

**Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Format` | String | No | `Markdown` | `Markdown` returns raw text. `Json` returns a note object with `content`, `frontmatter`, `path`, `stat`, and `tags`. `DocumentMap` returns `headings`, `blocks`, and `frontmatterFields` arrays. |

---

### Set-ObsidianActiveFile

Fully replaces the content of the active file. Supports `-WhatIf` and `-Confirm`.

**Syntax**
```powershell
Set-ObsidianActiveFile -Content <String>
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Content` | String | Yes | The new Markdown content |

---

### Add-ObsidianActiveFileContent

Appends content to the end of the active file.

**Syntax**
```powershell
Add-ObsidianActiveFileContent -Content <String>
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Content` | String | Yes | Content to append |

---

### Update-ObsidianActiveFileContent

Performs a surgical PATCH on the active file — insert content relative to a heading, block reference, or frontmatter field without touching the rest of the file. Supports `-WhatIf`.

**Syntax**
```powershell
Update-ObsidianActiveFileContent
    -Operation <append|prepend|replace>
    -TargetType <heading|block|frontmatter>
    -Target <String>
    -Content <String>
    [-TargetDelimiter <String>]
    [-TrimTargetWhitespace <true|false>]
    [-ContentType <text/markdown|application/json>]
    [-CreateTargetIfMissing]
```

**Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Operation` | String | Yes | - | `append`, `prepend`, or `replace` |
| `-TargetType` | String | Yes | - | `heading`, `block`, or `frontmatter` |
| `-Target` | String | Yes | - | Heading path (e.g. `Section::Subsection`), block ID, or frontmatter key |
| `-Content` | String | Yes | - | Content to insert |
| `-TargetDelimiter` | String | No | `::` | Separator for nested heading paths |
| `-TrimTargetWhitespace` | String | No | `false` | Trim whitespace when matching the target |
| `-ContentType` | String | No | `text/markdown` | `text/markdown` or `application/json` |
| `-CreateTargetIfMissing` | Switch | No | - | Create the target (e.g. frontmatter field) if it does not exist |

```powershell
# Append a line under a nested heading
Update-ObsidianActiveFileContent -Operation append -TargetType heading -Target 'Week::Monday' -Content '- Completed review'

# Replace a frontmatter field with a JSON value
Update-ObsidianActiveFileContent -Operation replace -TargetType frontmatter -Target 'status' -Content '"done"' -ContentType 'application/json' -CreateTargetIfMissing
```

---

### Remove-ObsidianActiveFile

Deletes the currently active file. ConfirmImpact is High — prompts unless `-Confirm:$false` is supplied.

**Syntax**
```powershell
Remove-ObsidianActiveFile [-Confirm:$false]
```

---

### Get-ObsidianVaultFile

Reads any file in the vault by its vault-relative path.

**Syntax**
```powershell
Get-ObsidianVaultFile -Path <String> [-Format <String>]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Path` | String | Yes | - | Vault-relative path, e.g. `Notes/my-note.md` |
| `-Format` | String | No | `Markdown` | `Markdown`, `Json`, or `DocumentMap` |

---

### Set-ObsidianVaultFile

Creates or fully replaces a vault file. Supports `-WhatIf` and `-Confirm`.

**Syntax**
```powershell
Set-ObsidianVaultFile -Path <String> -Content <String>
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Path` | String | Yes | Vault-relative path |
| `-Content` | String | Yes | New content (Markdown) |

---

### Add-ObsidianVaultFileContent

Appends content to a vault file. Creates an empty file first if the path does not exist.

**Syntax**
```powershell
Add-ObsidianVaultFileContent -Path <String> -Content <String>
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Path` | String | Yes | Vault-relative path |
| `-Content` | String | Yes | Content to append |

---

### Update-ObsidianVaultFileContent

Performs a surgical PATCH on any vault file. Same PATCH semantics as `Update-ObsidianActiveFileContent` but targets a file by path. Supports `-WhatIf`.

**Syntax**
```powershell
Update-ObsidianVaultFileContent
    -Path <String>
    -Operation <append|prepend|replace>
    -TargetType <heading|block|frontmatter>
    -Target <String>
    -Content <String>
    [-TargetDelimiter <String>]
    [-TrimTargetWhitespace <true|false>]
    [-ContentType <text/markdown|application/json>]
    [-CreateTargetIfMissing]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Path` | String | Yes | - | Vault-relative path |
| `-Operation` | String | Yes | - | `append`, `prepend`, or `replace` |
| `-TargetType` | String | Yes | - | `heading`, `block`, or `frontmatter` |
| `-Target` | String | Yes | - | Target identifier |
| `-Content` | String | Yes | - | Content to insert |
| `-TargetDelimiter` | String | No | `::` | Nested heading separator |
| `-TrimTargetWhitespace` | String | No | `false` | Trim target whitespace before matching |
| `-ContentType` | String | No | `text/markdown` | `text/markdown` or `application/json` |
| `-CreateTargetIfMissing` | Switch | No | - | Create the target if absent |

---

### Remove-ObsidianVaultFile

Deletes a file from the vault. ConfirmImpact is High.

**Syntax**
```powershell
Remove-ObsidianVaultFile -Path <String> [-Confirm:$false]
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Path` | String | Yes | Vault-relative path |

---

### Get-ObsidianVaultDirectory

Lists the immediate contents of a vault directory. Directory entries end with `/`.

**Syntax**
```powershell
Get-ObsidianVaultDirectory [-Path <String>]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Path` | String | No | - | Directory path relative to vault root. Omit to list the vault root. |

```powershell
# Vault root
Get-ObsidianVaultDirectory

# Subdirectory
Get-ObsidianVaultDirectory -Path 'Projects'

# Identify subdirectories vs files
Get-ObsidianVaultDirectory | Where-Object { $_ -like '*/' }
```

---

### Get-ObsidianPeriodicNote

Reads a periodic note. Without `-Date`, returns the current period's note. With `-Date`, returns the note for that specific date.

**Syntax**
```powershell
Get-ObsidianPeriodicNote [-Period <String>] [-Date <DateTime>] [-Format <String>]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Period` | String | No | `daily` | `daily`, `weekly`, `monthly`, `quarterly`, or `yearly` |
| `-Date` | DateTime | No | Current period | Specific date to target |
| `-Format` | String | No | `Markdown` | `Markdown`, `Json`, or `DocumentMap` |

```powershell
Get-ObsidianPeriodicNote -Period daily
Get-ObsidianPeriodicNote -Period weekly -Date (Get-Date '2026-01-05')
Get-ObsidianPeriodicNote -Period monthly -Format Json
```

---

### Set-ObsidianPeriodicNote

Replaces the entire content of a periodic note. Supports `-WhatIf` and `-Confirm`.

**Syntax**
```powershell
Set-ObsidianPeriodicNote -Content <String> [-Period <String>] [-Date <DateTime>]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Period` | String | No | `daily` | `daily`, `weekly`, `monthly`, `quarterly`, or `yearly` |
| `-Content` | String | Yes | - | New content |
| `-Date` | DateTime | No | Current period | Specific date to target |

---

### Add-ObsidianPeriodicNoteContent

Appends content to a periodic note. Creates the note if it does not exist.

**Syntax**
```powershell
Add-ObsidianPeriodicNoteContent -Content <String> [-Period <String>] [-Date <DateTime>]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Period` | String | No | `daily` | `daily`, `weekly`, `monthly`, `quarterly`, or `yearly` |
| `-Content` | String | Yes | - | Content to append |
| `-Date` | DateTime | No | Current period | Specific date to target |

---

### Update-ObsidianPeriodicNoteContent

Performs a surgical PATCH on a periodic note. Same PATCH semantics as the other `Update-*Content` commands. Supports `-WhatIf`.

**Syntax**
```powershell
Update-ObsidianPeriodicNoteContent
    -Operation <append|prepend|replace>
    -TargetType <heading|block|frontmatter>
    -Target <String>
    -Content <String>
    [-Period <String>]
    [-Date <DateTime>]
    [-TargetDelimiter <String>]
    [-TrimTargetWhitespace <true|false>]
    [-ContentType <text/markdown|application/json>]
    [-CreateTargetIfMissing]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Period` | String | No | `daily` | `daily`, `weekly`, `monthly`, `quarterly`, or `yearly` |
| `-Date` | DateTime | No | Current period | Specific date to target |
| `-Operation` | String | Yes | - | `append`, `prepend`, or `replace` |
| `-TargetType` | String | Yes | - | `heading`, `block`, or `frontmatter` |
| `-Target` | String | Yes | - | Target identifier |
| `-Content` | String | Yes | - | Content to insert |
| `-TargetDelimiter` | String | No | `::` | Nested heading separator |
| `-TrimTargetWhitespace` | String | No | `false` | Trim target whitespace before matching |
| `-ContentType` | String | No | `text/markdown` | `text/markdown` or `application/json` |
| `-CreateTargetIfMissing` | Switch | No | - | Create the target if absent |

---

### Remove-ObsidianPeriodicNote

Deletes a periodic note. ConfirmImpact is High.

**Syntax**
```powershell
Remove-ObsidianPeriodicNote [-Period <String>] [-Date <DateTime>] [-Confirm:$false]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Period` | String | No | `daily` | `daily`, `weekly`, `monthly`, `quarterly`, or `yearly` |
| `-Date` | DateTime | No | Current period | Specific date to target |

---

### Search-ObsidianVault

Advanced search using JsonLogic expressions or Dataview DQL queries.

**Syntax**
```powershell
Search-ObsidianVault -Query <String> -QueryType <JsonLogic|DataviewDQL>
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Query` | String | Yes | JsonLogic JSON string or Dataview DQL statement |
| `-QueryType` | String | Yes | `JsonLogic` or `DataviewDQL` |

```powershell
# JsonLogic: notes tagged 'project'
Search-ObsidianVault -Query '{"in": ["project", {"var": "tags"}]}' -QueryType JsonLogic

# Dataview DQL: table query
Search-ObsidianVault -Query 'TABLE status, owner FROM "Projects"' -QueryType DataviewDQL
```

Note: `DataviewDQL` requires the [Dataview plugin](https://github.com/blacksmithgu/obsidian-dataview) to be installed and enabled in Obsidian.

---

### Search-ObsidianVaultSimple

Full-text search that returns matching files with surrounding context for each match.

**Syntax**
```powershell
Search-ObsidianVaultSimple -Query <String> [-ContextLength <Int>]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `-Query` | String | Yes | - | Text to search for |
| `-ContextLength` | Int | No | `100` | Characters of context returned around each match |

```powershell
$results = Search-ObsidianVaultSimple -Query 'standup' -ContextLength 150
$results | Select-Object filename, @{n='Matches';e={$_.matches.Count}}
```

---

### Open-ObsidianFile

Tells the Obsidian UI to open a file. Creates the file if it does not exist.

**Syntax**
```powershell
Open-ObsidianFile -Path <String> [-NewLeaf]
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `-Path` | String | Yes | Vault-relative path |
| `-NewLeaf` | Switch | No | Open in a new tab/pane instead of the current one |

```powershell
Open-ObsidianFile -Path 'Notes/meeting-2026-03-13.md'
Open-ObsidianFile -Path 'Notes/reference.md' -NewLeaf
```

---

## Troubleshooting

### "Not connected to Obsidian API. Run Connect-ObsidianApi first."

You called a function before `Connect-ObsidianApi`, or the module was reloaded. Run `Connect-ObsidianApi` again.

### "Failed to connect to Obsidian API at https://127.0.0.1:27124"

- Verify Obsidian is running.
- Verify the Local REST API plugin is enabled (Settings > Community plugins).
- Check the port matches the plugin setting (default `27124`).
- Check that nothing else is binding that port.

### "Authentication failed. The API key was not accepted by the Obsidian server."

The key was rejected by Obsidian. Copy the key again directly from Settings > Local REST API in Obsidian — no leading/trailing whitespace.

### TLS/Certificate errors on non-localhost connections

By default, certificate checking is only skipped for `127.0.0.1`, `localhost`, and `::1`. For any other `BaseUrl`, pass `-SkipCertificateCheck` or add the certificate (retrieved with `Get-ObsidianApiCertificate`) to your system trust store.

### "Obsidian API error (404): ..."

The file or periodic note does not exist in the vault. Check the path and whether the relevant Obsidian plugin (e.g. Calendar, Periodic Notes) is installed.

### "Obsidian API error (400): ..."

A PATCH operation targeted a heading, block, or frontmatter field that does not exist. Add `-CreateTargetIfMissing` (for frontmatter) or verify the target string exactly matches the content in the note.

### Linux/macOS: "File not found" for a path you know exists

Vault paths are case-sensitive on the API side on all platforms. `Notes/MyNote.md` and `Notes/mynote.md` are different files.

### Windows: Execution policy blocks the module

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Verifying the connection without a full connect

```powershell
# Does not require authentication
Get-ObsidianServerStatus
```

If this returns a response, Obsidian is running and the plugin is active. If it fails, the issue is network/firewall/port rather than authentication.
