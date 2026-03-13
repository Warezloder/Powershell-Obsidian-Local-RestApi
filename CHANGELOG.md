# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-03-13

### Added

#### Connection Management
- `Connect-ObsidianApi` — Authenticates with the Obsidian Local REST API. Stores the API key and base URL in module scope. Validates the connection immediately by calling the server status endpoint and throws on failure so credentials are never left in an invalid state. Auto-enables certificate bypass for localhost addresses (`127.0.0.1`, `localhost`, `::1`).
- `Disconnect-ObsidianApi` — Clears all stored credentials from module scope.

#### System Endpoints
- `Get-ObsidianServerStatus` — Returns server version information and authentication state. The only endpoint callable without authentication.
- `Get-ObsidianApiCertificate` — Downloads the self-signed TLS certificate. Optionally saves to a file via `-OutFile`.
- `Get-ObsidianApiSpec` — Downloads the OpenAPI YAML specification. Optionally saves to a file via `-OutFile`.

#### Commands
- `Get-ObsidianCommand` — Lists all registered Obsidian commands. Supports wildcard filtering via `-Name`.
- `Invoke-ObsidianCommand` — Executes a command by ID. Accepts pipeline input from `Get-ObsidianCommand` via the `id` property alias.

#### Active File Operations
- `Get-ObsidianActiveFile` — Reads the currently open file. Supports three response formats: `Markdown` (raw text), `Json` (structured note object with frontmatter, tags, path, and stat), and `DocumentMap` (headings, blocks, and frontmatter field arrays).
- `Set-ObsidianActiveFile` — Fully replaces the active file's content. Supports `-WhatIf` and `-Confirm` (ConfirmImpact: Medium).
- `Add-ObsidianActiveFileContent` — Appends content to the active file.
- `Update-ObsidianActiveFileContent` — Surgically patches the active file at a heading, block reference, or frontmatter field using `append`, `prepend`, or `replace` operations. Supports `-WhatIf`.
- `Remove-ObsidianActiveFile` — Deletes the active file. Supports `-WhatIf` and `-Confirm` (ConfirmImpact: High).

#### Vault File Operations
- `Get-ObsidianVaultFile` — Reads any vault file by vault-relative path. Supports `Markdown`, `Json`, and `DocumentMap` formats.
- `Set-ObsidianVaultFile` — Creates or fully replaces a vault file. Supports `-WhatIf` and `-Confirm` (ConfirmImpact: Medium).
- `Add-ObsidianVaultFileContent` — Appends content to a vault file. Creates the file if it does not exist.
- `Update-ObsidianVaultFileContent` — Surgically patches any vault file at a heading, block reference, or frontmatter field. Supports `-WhatIf`.
- `Remove-ObsidianVaultFile` — Deletes a vault file. Supports `-WhatIf` and `-Confirm` (ConfirmImpact: High).

#### Vault Directory Operations
- `Get-ObsidianVaultDirectory` — Lists files and subdirectories in the vault root or any subdirectory. Directory entries are returned with a trailing `/`.

#### Periodic Note Operations
- `Get-ObsidianPeriodicNote` — Reads a periodic note for `daily`, `weekly`, `monthly`, `quarterly`, or `yearly` periods. Supports current period (no `-Date`) and specific dated notes. Supports `Markdown`, `Json`, and `DocumentMap` formats.
- `Set-ObsidianPeriodicNote` — Fully replaces a periodic note. Supports `-WhatIf` and `-Confirm` (ConfirmImpact: Medium).
- `Add-ObsidianPeriodicNoteContent` — Appends content to a periodic note. Creates the note if it does not exist.
- `Update-ObsidianPeriodicNoteContent` — Surgically patches a periodic note at a heading, block reference, or frontmatter field. Supports `-WhatIf`.
- `Remove-ObsidianPeriodicNote` — Deletes a periodic note. Supports `-WhatIf` and `-Confirm` (ConfirmImpact: High).

#### Search
- `Search-ObsidianVault` — Advanced search using JsonLogic JSON expressions or Dataview DQL queries (requires the Dataview plugin for DQL).
- `Search-ObsidianVaultSimple` — Full-text search returning matching files with configurable surrounding context via `-ContextLength`.

#### Open
- `Open-ObsidianFile` — Opens a vault file in the Obsidian UI. Creates the file if absent. Supports `-NewLeaf` to open in a new tab/pane.

#### Private Helpers
- `Invoke-ObsidianRestMethod` — Central HTTP wrapper. Handles authorization header injection, base URL construction, self-signed certificate bypass, and structured error message extraction from API error responses.
- `Invoke-ObsidianPatchOperation` — Shared PATCH helper used by all three `Update-*Content` functions. Builds the `Operation`, `Target-Type`, `Target`, `Target-Delimiter`, `Trim-Target-Whitespace`, and optional `Create-Target-If-Missing` request headers.
- `ConvertTo-ObsidianEncodedPath` — Normalizes vault paths (backslash to forward slash) and URL-encodes each segment for safe URI construction.
- `Get-ObsidianPeriodicNoteUri` — Builds the correct periodic note URI for current-period and dated requests.

### Module Characteristics
- Requires PowerShell 7.0 or higher
- Cross-platform: Windows, Linux, macOS
- 26 exported functions, 4 private helpers
- 147 Pester tests, all passing (92.93% code coverage)
- ShouldProcess / `-WhatIf` / `-Confirm` on all write and delete operations
- Three response formats (Markdown, Json, DocumentMap) on all file-read operations
- Automatic localhost certificate bypass; manual override via `-SkipCertificateCheck`
- Windows backslash paths accepted and normalized transparently
