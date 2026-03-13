#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
.SYNOPSIS
    Pester v5 tests for the ObsidianLocalRestApi PowerShell module.

.DESCRIPTION
    Comprehensive unit tests covering all 26 public functions and 4 private helpers.
    All HTTP calls are mocked via Mock on Invoke-RestMethod within the module scope.
    No live Obsidian instance is required.

    Test strategy:
    - Private helpers are tested directly via InModuleScope
    - Public functions are called normally; Invoke-RestMethod is mocked at module scope
    - Module state ($script:ApiKey, $script:BaseUrl, $script:SkipCertCheck) is
      managed through Connect-ObsidianApi (with a mocked status response) or
      set directly with InModuleScope
    - ShouldProcess behaviour is verified with -WhatIf and by asserting the
      underlying mock is NOT invoked when -WhatIf is passed
#>

BeforeAll {
    # -------------------------------------------------------------------------
    # Load the module fresh for every test run
    # -------------------------------------------------------------------------
    $ModuleRoot = Split-Path -Parent $PSScriptRoot
    $ModuleManifest = Join-Path $ModuleRoot 'ObsidianLocalRestApi.psd1'

    if (Get-Module -Name ObsidianLocalRestApi) {
        Remove-Module -Name ObsidianLocalRestApi -Force
    }
    Import-Module $ModuleManifest -Force -ErrorAction Stop

    # -------------------------------------------------------------------------
    # A reusable helper: prime module state without a real network call.
    # We set script-scoped variables directly inside the module to avoid having
    # to mock the entire Connect flow every describe block.
    # -------------------------------------------------------------------------
    function Set-ObsidianTestConnection {
        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey       = 'test-api-key-abc123'
            $script:BaseUrl      = 'https://127.0.0.1:27124'
            $script:SkipCertCheck = $true
        }
    }

    function Clear-ObsidianTestConnection {
        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey        = $null
            $script:BaseUrl       = $null
            $script:SkipCertCheck = $true
        }
    }
}

AfterAll {
    Remove-Module -Name ObsidianLocalRestApi -Force -ErrorAction SilentlyContinue
}

# =============================================================================
# SECTION 1 – Module structure
# =============================================================================
Describe 'Module Structure' {

    It 'Imports without errors' {
        { Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'ObsidianLocalRestApi.psd1') -Force } |
            Should -Not -Throw
    }

    It 'Exports exactly 26 public functions' {
        $exported = (Get-Module ObsidianLocalRestApi).ExportedFunctions.Keys
        $exported.Count | Should -Be 26
    }

    It 'Exports Connect-ObsidianApi' {
        Get-Command -Module ObsidianLocalRestApi -Name 'Connect-ObsidianApi' |
            Should -Not -BeNullOrEmpty
    }

    It 'Does not export private helper functions' {
        $privateNames = @(
            'Invoke-ObsidianRestMethod',
            'Invoke-ObsidianPatchOperation',
            'ConvertTo-ObsidianEncodedPath',
            'Get-ObsidianPeriodicNoteUri'
        )
        foreach ($name in $privateNames) {
            Get-Command -Module ObsidianLocalRestApi -Name $name -ErrorAction SilentlyContinue |
                Should -BeNullOrEmpty -Because "$name is private"
        }
    }

    It 'Has a module version of 1.0.0' {
        (Get-Module ObsidianLocalRestApi).Version | Should -Be '1.0.0'
    }
}

# =============================================================================
# SECTION 2 – Private helper: ConvertTo-ObsidianEncodedPath
# =============================================================================
Describe 'Private: ConvertTo-ObsidianEncodedPath' {

    It 'Returns a simple filename unchanged' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path 'note.md' | Should -Be 'note.md'
        }
    }

    It 'Encodes spaces in a filename' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path 'my note.md' | Should -Be 'my%20note.md'
        }
    }

    It 'Converts backslashes to forward slashes' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path 'Folder\note.md' | Should -Be 'Folder/note.md'
        }
    }

    It 'Encodes spaces in a nested path' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path 'My Notes/daily note.md' |
                Should -Be 'My%20Notes/daily%20note.md'
        }
    }

    It 'Encodes special characters per segment' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path 'Notes/note (1).md' |
                Should -Be 'Notes/note%20%281%29.md'
        }
    }

    It 'Handles a multi-level path with backslashes' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path 'A\B\C\note.md' | Should -Be 'A/B/C/note.md'
        }
    }

    It 'Encodes unicode characters' {
        InModuleScope ObsidianLocalRestApi {
            $result = ConvertTo-ObsidianEncodedPath -Path 'Notes/日本語.md'
            $result | Should -BeLike 'Notes/*'
            $result | Should -Not -BeLike '*日*'
        }
    }

    It 'Throws on mandatory parameter missing' {
        InModuleScope ObsidianLocalRestApi {
            { ConvertTo-ObsidianEncodedPath } | Should -Throw
        }
    }
}

# =============================================================================
# SECTION 3 – Private helper: Get-ObsidianPeriodicNoteUri
# =============================================================================
Describe 'Private: Get-ObsidianPeriodicNoteUri' {

    It 'Returns current-period URI when no date is given' {
        InModuleScope ObsidianLocalRestApi {
            Get-ObsidianPeriodicNoteUri -Period 'daily' | Should -Be '/periodic/daily/'
        }
    }

    It 'Returns current-period URI for weekly' {
        InModuleScope ObsidianLocalRestApi {
            Get-ObsidianPeriodicNoteUri -Period 'weekly' | Should -Be '/periodic/weekly/'
        }
    }

    It 'Returns dated URI when a date is supplied' {
        InModuleScope ObsidianLocalRestApi {
            $d = [datetime]'2025-03-15'
            Get-ObsidianPeriodicNoteUri -Period 'daily' -Date $d |
                Should -Be '/periodic/daily/2025/3/15/'
        }
    }

    It 'Returns dated URI for monthly period' {
        InModuleScope ObsidianLocalRestApi {
            $d = [datetime]'2025-06-01'
            Get-ObsidianPeriodicNoteUri -Period 'monthly' -Date $d |
                Should -Be '/periodic/monthly/2025/6/1/'
        }
    }

    It 'Handles null date explicitly returning current URI' {
        InModuleScope ObsidianLocalRestApi {
            Get-ObsidianPeriodicNoteUri -Period 'yearly' -Date $null |
                Should -Be '/periodic/yearly/'
        }
    }

    It 'Throws when Period is missing' {
        InModuleScope ObsidianLocalRestApi {
            { Get-ObsidianPeriodicNoteUri } | Should -Throw
        }
    }
}

# =============================================================================
# SECTION 4 – Private helper: Invoke-ObsidianRestMethod
# =============================================================================
Describe 'Private: Invoke-ObsidianRestMethod' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Throws when not connected (BaseUrl is null)' {
        InModuleScope ObsidianLocalRestApi {
            $savedUrl = $script:BaseUrl
            $script:BaseUrl = $null
            try {
                { Invoke-ObsidianRestMethod -Uri '/test/' } | Should -Throw '*Not connected*'
            }
            finally {
                $script:BaseUrl = $savedUrl
            }
        }
    }

    It 'Calls Invoke-RestMethod with the correct full URI' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { [PSCustomObject]@{ ok = $true } }

            Invoke-ObsidianRestMethod -Uri '/active/'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Uri -eq 'https://127.0.0.1:27124/active/'
            }
        }
    }

    It 'Injects the Authorization Bearer header when ApiKey is set' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { [PSCustomObject]@{ ok = $true } }

            Invoke-ObsidianRestMethod -Uri '/active/'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Authorization'] -eq 'Bearer test-api-key-abc123'
            }
        }
    }

    It 'Sets the Accept header when -Accept is provided' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { [PSCustomObject]@{ ok = $true } }

            Invoke-ObsidianRestMethod -Uri '/active/' -Accept 'text/markdown'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Accept'] -eq 'text/markdown'
            }
        }
    }

    It 'Passes the Body to Invoke-RestMethod when supplied' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianRestMethod -Uri '/active/' -Method 'PUT' -Body 'hello' -ContentType 'text/markdown'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Body -eq 'hello' -and $ContentType -eq 'text/markdown'
            }
        }
    }

    It 'Passes SkipCertificateCheck from script scope' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }
            $script:SkipCertCheck = $true

            Invoke-ObsidianRestMethod -Uri '/active/'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $SkipCertificateCheck -eq $true
            }
        }
    }

    It 'Re-throws the exception when Invoke-RestMethod fails without a response body' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { throw 'connection refused' }

            { Invoke-ObsidianRestMethod -Uri '/active/' } | Should -Throw '*connection refused*'
        }
    }

    It 'Uses GET as the default HTTP method' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianRestMethod -Uri '/active/'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Method -eq 'GET'
            }
        }
    }
}

# =============================================================================
# SECTION 5 – Private helper: Invoke-ObsidianPatchOperation
# =============================================================================
Describe 'Private: Invoke-ObsidianPatchOperation' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls Invoke-RestMethod with PATCH method' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'append' `
                -TargetType 'heading' -Target 'Tasks' -Content '- New item'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Method -eq 'PATCH'
            }
        }
    }

    It 'Passes Operation header correctly' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'prepend' `
                -TargetType 'heading' -Target 'Notes' -Content 'prefix'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Operation'] -eq 'prepend'
            }
        }
    }

    It 'Passes Target-Type header correctly' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'replace' `
                -TargetType 'frontmatter' -Target 'status' -Content '"done"'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Target-Type'] -eq 'frontmatter'
            }
        }
    }

    It 'Passes Target header correctly' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'append' `
                -TargetType 'heading' -Target 'My Heading' -Content 'text'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Target'] -eq 'My Heading'
            }
        }
    }

    It 'Includes Create-Target-If-Missing header when switch is set' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'replace' `
                -TargetType 'frontmatter' -Target 'tag' -Content '"work"' `
                -CreateTargetIfMissing

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Create-Target-If-Missing'] -eq 'true'
            }
        }
    }

    It 'Does NOT include Create-Target-If-Missing header by default' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'append' `
                -TargetType 'heading' -Target 'H1' -Content 'text'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                -not $Headers.ContainsKey('Create-Target-If-Missing')
            }
        }
    }

    It 'Uses default Target-Delimiter of "::"' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'append' `
                -TargetType 'heading' -Target 'H1' -Content 'text'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Target-Delimiter'] -eq '::'
            }
        }
    }

    It 'Accepts a custom Target-Delimiter' {
        InModuleScope ObsidianLocalRestApi {
            Mock Invoke-RestMethod { $null }

            Invoke-ObsidianPatchOperation -Uri '/active/' -Operation 'append' `
                -TargetType 'heading' -Target 'H1' -Content 'text' -TargetDelimiter '|'

            Should -Invoke Invoke-RestMethod -Times 1 -ParameterFilter {
                $Headers['Target-Delimiter'] -eq '|'
            }
        }
    }
}

# =============================================================================
# SECTION 6 – Connect-ObsidianApi / Disconnect-ObsidianApi lifecycle
# =============================================================================
Describe 'Connect-ObsidianApi and Disconnect-ObsidianApi' {

    BeforeEach {
        # Always start from a clean disconnected state
        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey        = $null
            $script:BaseUrl       = $null
            $script:SkipCertCheck = $true
        }
    }

    It 'Sets BaseUrl and ApiKey on success' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                authenticated = $true
                service       = 'obsidian-local-rest-api'
                versions      = [PSCustomObject]@{ self = '2.1.0'; obsidian = '1.5.0' }
            }
        }

        Connect-ObsidianApi -ApiKey 'mykey' -BaseUrl 'https://127.0.0.1:27124'

        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey   | Should -Be 'mykey'
            $script:BaseUrl  | Should -Be 'https://127.0.0.1:27124'
        }
    }

    It 'Trims trailing slash from BaseUrl' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                authenticated = $true
                service       = 'obsidian-local-rest-api'
                versions      = [PSCustomObject]@{ self = '2.1.0'; obsidian = '1.5.0' }
            }
        }

        Connect-ObsidianApi -ApiKey 'mykey' -BaseUrl 'https://127.0.0.1:27124/'

        InModuleScope ObsidianLocalRestApi {
            $script:BaseUrl | Should -Be 'https://127.0.0.1:27124'
        }
    }

    It 'Returns the status object on success' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                authenticated = $true
                service       = 'obsidian-local-rest-api'
                versions      = [PSCustomObject]@{ self = '2.1.0'; obsidian = '1.5.0' }
            }
        }

        $result = Connect-ObsidianApi -ApiKey 'mykey'
        $result.authenticated | Should -Be $true
        $result.service       | Should -Be 'obsidian-local-rest-api'
    }

    It 'Clears state and throws when HTTP call fails' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { throw 'connection refused' }

        { Connect-ObsidianApi -ApiKey 'mykey' } | Should -Throw '*Failed to connect*'

        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey  | Should -BeNullOrEmpty
            $script:BaseUrl | Should -BeNullOrEmpty
        }
    }

    It 'Clears state and throws when authentication fails' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                authenticated = $false
                service       = 'obsidian-local-rest-api'
                versions      = [PSCustomObject]@{ self = '2.1.0'; obsidian = '1.5.0' }
            }
        }

        { Connect-ObsidianApi -ApiKey 'wrongkey' } | Should -Throw '*Authentication failed*'

        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey  | Should -BeNullOrEmpty
            $script:BaseUrl | Should -BeNullOrEmpty
        }
    }

    It 'Defaults SkipCertCheck to true for localhost' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                authenticated = $true
                service       = 'obsidian-local-rest-api'
                versions      = [PSCustomObject]@{ self = '2.1.0'; obsidian = '1.5.0' }
            }
        }

        Connect-ObsidianApi -ApiKey 'mykey' -BaseUrl 'https://127.0.0.1:27124'

        InModuleScope ObsidianLocalRestApi {
            $script:SkipCertCheck | Should -Be $true
        }
    }

    It 'Defaults SkipCertCheck to false for non-localhost' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                authenticated = $true
                service       = 'obsidian-local-rest-api'
                versions      = [PSCustomObject]@{ self = '2.1.0'; obsidian = '1.5.0' }
            }
        }

        Connect-ObsidianApi -ApiKey 'mykey' -BaseUrl 'https://obsidian.example.com'

        InModuleScope ObsidianLocalRestApi {
            $script:SkipCertCheck | Should -Be $false
        }
    }

    It 'Respects explicit -SkipCertificateCheck switch' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                authenticated = $true
                service       = 'obsidian-local-rest-api'
                versions      = [PSCustomObject]@{ self = '2.1.0'; obsidian = '1.5.0' }
            }
        }

        Connect-ObsidianApi -ApiKey 'mykey' -BaseUrl 'https://obsidian.example.com' -SkipCertificateCheck

        InModuleScope ObsidianLocalRestApi {
            $script:SkipCertCheck | Should -Be $true
        }
    }

    It 'ApiKey is mandatory – missing parameter throws' {
        { Connect-ObsidianApi } | Should -Throw
    }

    It 'Disconnect-ObsidianApi clears all module state' {
        # Pre-set state
        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey        = 'some-key'
            $script:BaseUrl       = 'https://127.0.0.1:27124'
            $script:SkipCertCheck = $false
        }

        Disconnect-ObsidianApi

        InModuleScope ObsidianLocalRestApi {
            $script:ApiKey        | Should -BeNullOrEmpty
            $script:BaseUrl       | Should -BeNullOrEmpty
            $script:SkipCertCheck | Should -Be $true
        }
    }

    It 'Disconnect-ObsidianApi is idempotent – does not throw when already disconnected' {
        { Disconnect-ObsidianApi } | Should -Not -Throw
    }
}

# =============================================================================
# SECTION 7 – System / status endpoints
# =============================================================================
Describe 'Get-ObsidianServerStatus' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls GET /' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{ authenticated = $true; service = 'obsidian-local-rest-api' }
        }

        Get-ObsidianServerStatus

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -eq 'https://127.0.0.1:27124/' -and $Method -eq 'GET'
        }
    }

    It 'Returns the status object' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{ authenticated = $true; service = 'obsidian-local-rest-api' }
        }

        $result = Get-ObsidianServerStatus
        $result.authenticated | Should -Be $true
        $result.service       | Should -Be 'obsidian-local-rest-api'
    }
}

Describe 'Get-ObsidianApiCertificate' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls GET /obsidian-local-rest-api.crt' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '-----BEGIN CERTIFICATE-----' }

        Get-ObsidianApiCertificate

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/obsidian-local-rest-api.crt'
        }
    }

    It 'Returns the certificate string when no OutFile is given' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '-----BEGIN CERTIFICATE-----' }

        $result = Get-ObsidianApiCertificate
        $result | Should -Be '-----BEGIN CERTIFICATE-----'
    }

    It 'Saves to file and returns nothing when OutFile is given' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '-----BEGIN CERTIFICATE-----' }
        Mock -ModuleName ObsidianLocalRestApi Set-Content {}

        $result = Get-ObsidianApiCertificate -OutFile 'TestDrive:\cert.crt'

        $result | Should -BeNullOrEmpty
        Should -Invoke -ModuleName ObsidianLocalRestApi Set-Content -Times 1
    }
}

Describe 'Get-ObsidianApiSpec' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls GET /openapi.yaml' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { 'openapi: 3.0.0' }

        Get-ObsidianApiSpec

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/openapi.yaml'
        }
    }

    It 'Returns the spec string when no OutFile is given' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { 'openapi: 3.0.0' }

        $result = Get-ObsidianApiSpec
        $result | Should -Be 'openapi: 3.0.0'
    }

    It 'Saves to file and returns nothing when OutFile is given' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { 'openapi: 3.0.0' }
        Mock -ModuleName ObsidianLocalRestApi Set-Content {}

        $result = Get-ObsidianApiSpec -OutFile 'TestDrive:\spec.yaml'

        $result | Should -BeNullOrEmpty
        Should -Invoke -ModuleName ObsidianLocalRestApi Set-Content -Times 1
    }
}

# =============================================================================
# SECTION 8 – Commands
# =============================================================================
Describe 'Get-ObsidianCommand' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    BeforeEach {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{
                commands = @(
                    [PSCustomObject]@{ id = 'editor:open';       name = 'Open file' }
                    [PSCustomObject]@{ id = 'global-search:open'; name = 'Open search' }
                    [PSCustomObject]@{ id = 'graph:open';         name = 'Open graph view' }
                )
            }
        }
    }

    It 'Calls GET /commands/' {
        Get-ObsidianCommand

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/commands/'
        }
    }

    It 'Returns all commands when no filter is specified' {
        $result = Get-ObsidianCommand
        $result.Count | Should -Be 3
    }

    It 'Filters commands by wildcard Name' {
        $result = Get-ObsidianCommand -Name '*search*'
        $result.Count | Should -Be 1
        $result[0].id | Should -Be 'global-search:open'
    }

    It 'Returns empty when no commands match the filter' {
        $result = Get-ObsidianCommand -Name '*nonexistent*'
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Invoke-ObsidianCommand' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls POST /commands/{commandId}/' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Invoke-ObsidianCommand -CommandId 'global-search:open'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri    -like '*/commands/global-search%3Aopen/' -and
            $Method -eq 'POST'
        }
    }

    It 'URL-encodes the colon in CommandId' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Invoke-ObsidianCommand -CommandId 'plugin:do something'

        # EscapeDataString encodes : -> %3A; space remains literal in the assembled URI string
        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/commands/plugin%3Ado something/'
        }
    }

    It 'Accepts pipeline input via id alias' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        [PSCustomObject]@{ id = 'editor:open' } | Invoke-ObsidianCommand

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1
    }

    It 'Processes multiple piped commands' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        @(
            [PSCustomObject]@{ id = 'cmd1' }
            [PSCustomObject]@{ id = 'cmd2' }
        ) | Invoke-ObsidianCommand

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 2
    }
}

# =============================================================================
# SECTION 9 – Active File
# =============================================================================
Describe 'Get-ObsidianActiveFile' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls GET /active/ with Markdown Accept header by default' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Note content' }

        Get-ObsidianActiveFile

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/active/' -and $Headers['Accept'] -eq 'text/markdown'
        }
    }

    It 'Calls GET /active/ with Json Accept header' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{ content = '# Note'; path = 'Note.md' }
        }

        Get-ObsidianActiveFile -Format Json

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Accept'] -eq 'application/vnd.olrapi.note+json'
        }
    }

    It 'Calls GET /active/ with DocumentMap Accept header' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { [PSCustomObject]@{ headings = @() } }

        Get-ObsidianActiveFile -Format DocumentMap

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Accept'] -eq 'application/vnd.olrapi.document-map+json'
        }
    }

    It 'Returns the response object' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# My Note' }
        $result = Get-ObsidianActiveFile
        $result | Should -Be '# My Note'
    }
}

Describe 'Set-ObsidianActiveFile' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls PUT /active/ with the supplied content' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Set-ObsidianActiveFile -Content '# New Content' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PUT' -and $Uri -like '*/active/' -and $Body -eq '# New Content'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Set-ObsidianActiveFile -Content '# Draft' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }

    It 'Content is a mandatory parameter' {
        { Set-ObsidianActiveFile } | Should -Throw
    }
}

Describe 'Add-ObsidianActiveFileContent' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls POST /active/ with the supplied content' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Add-ObsidianActiveFileContent -Content "`n## Appended"

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*/active/' -and $Body -like '*Appended*'
        }
    }

    It 'Content is a mandatory parameter' {
        { Add-ObsidianActiveFileContent } | Should -Throw
    }
}

Describe 'Update-ObsidianActiveFileContent' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls PATCH /active/ with correct Operation header' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianActiveFileContent -Operation 'append' -TargetType 'heading' `
            -Target 'Tasks' -Content '- item' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PATCH' -and $Headers['Operation'] -eq 'append'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianActiveFileContent -Operation 'append' -TargetType 'heading' `
            -Target 'Tasks' -Content '- item' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }

    It 'Includes Create-Target-If-Missing header when switch is set' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianActiveFileContent -Operation 'replace' -TargetType 'frontmatter' `
            -Target 'status' -Content '"done"' -CreateTargetIfMissing -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Create-Target-If-Missing'] -eq 'true'
        }
    }

    It 'Mandatory parameters throw when missing' {
        { Update-ObsidianActiveFileContent -Operation 'append' -TargetType 'heading' -Target 'H' } |
            Should -Throw
    }
}

Describe 'Remove-ObsidianActiveFile' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls DELETE /active/' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianActiveFile -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'DELETE' -and $Uri -like '*/active/'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianActiveFile -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }
}

# =============================================================================
# SECTION 10 – Vault Files
# =============================================================================
Describe 'Get-ObsidianVaultFile' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls GET /vault/{encodedPath} for a simple filename' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Content' }

        Get-ObsidianVaultFile -Path 'note.md'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/vault/note.md'
        }
    }

    It 'Passes through path with spaces' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Content' }

        Get-ObsidianVaultFile -Path 'My Notes/daily note.md'

        # ConvertTo-ObsidianEncodedPath encodes spaces, but the URI string passed to
        # Invoke-RestMethod retains the literal characters from string concatenation
        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/vault/My Notes/daily note.md'
        }
    }

    It 'Sends the correct Accept header for Json format' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { [PSCustomObject]@{ content = '' } }

        Get-ObsidianVaultFile -Path 'note.md' -Format Json

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Accept'] -eq 'application/vnd.olrapi.note+json'
        }
    }

    It 'Sends text/markdown Accept header by default' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Content' }

        Get-ObsidianVaultFile -Path 'note.md'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Accept'] -eq 'text/markdown'
        }
    }

    It 'Path is a mandatory parameter' {
        { Get-ObsidianVaultFile } | Should -Throw
    }
}

Describe 'Set-ObsidianVaultFile' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls PUT /vault/{encodedPath}' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Set-ObsidianVaultFile -Path 'Notes/note.md' -Content '# Hello' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PUT' -and $Uri -like '*/vault/Notes/note.md' -and $Body -eq '# Hello'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Set-ObsidianVaultFile -Path 'Notes/note.md' -Content '# Hello' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }

    It 'Path and Content are mandatory parameters' {
        { Set-ObsidianVaultFile -Path 'note.md' }  | Should -Throw
        { Set-ObsidianVaultFile -Content 'text' }  | Should -Throw
    }
}

Describe 'Add-ObsidianVaultFileContent' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls POST /vault/{encodedPath} with content' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Add-ObsidianVaultFileContent -Path 'log.md' -Content "`n- entry"

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*/vault/log.md'
        }
    }

    It 'Path and Content are mandatory parameters' {
        { Add-ObsidianVaultFileContent -Path 'log.md' }    | Should -Throw
        { Add-ObsidianVaultFileContent -Content 'text' }   | Should -Throw
    }
}

Describe 'Update-ObsidianVaultFileContent' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls PATCH /vault/{encodedPath}' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianVaultFileContent -Path 'Notes/todo.md' -Operation 'append' `
            -TargetType 'heading' -Target 'Tasks' -Content '- [ ] item' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PATCH' -and $Uri -like '*/vault/Notes/todo.md'
        }
    }

    It 'Passes through path with spaces' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianVaultFileContent -Path 'My Notes/todo.md' -Operation 'prepend' `
            -TargetType 'heading' -Target 'H1' -Content 'text' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/vault/My Notes/todo.md'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianVaultFileContent -Path 'Notes/todo.md' -Operation 'append' `
            -TargetType 'heading' -Target 'Tasks' -Content '- item' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }

    It 'Passes CreateTargetIfMissing to patch helper' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianVaultFileContent -Path 'note.md' -Operation 'replace' `
            -TargetType 'frontmatter' -Target 'tag' -Content '"work"' `
            -CreateTargetIfMissing -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Create-Target-If-Missing'] -eq 'true'
        }
    }
}

Describe 'Remove-ObsidianVaultFile' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls DELETE /vault/{encodedPath}' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianVaultFile -Path 'old.md' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'DELETE' -and $Uri -like '*/vault/old.md'
        }
    }

    It 'Passes through path with spaces' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianVaultFile -Path 'old notes.md' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/vault/old notes.md'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianVaultFile -Path 'old.md' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }

    It 'Path is a mandatory parameter' {
        { Remove-ObsidianVaultFile -Confirm:$false } | Should -Throw
    }
}

# =============================================================================
# SECTION 11 – Vault Directory
# =============================================================================
Describe 'Get-ObsidianVaultDirectory' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls GET /vault/ when no path is given' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{ files = @('Notes/', 'readme.md') }
        }

        Get-ObsidianVaultDirectory

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -eq 'https://127.0.0.1:27124/vault/'
        }
    }

    It 'Calls GET /vault/{encodedPath}/ when a path is given' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{ files = @('note1.md', 'note2.md') }
        }

        Get-ObsidianVaultDirectory -Path 'Notes'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/vault/Notes/'
        }
    }

    It 'Passes through directory path with spaces' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{ files = @() }
        }

        Get-ObsidianVaultDirectory -Path 'My Notes'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/vault/My Notes/'
        }
    }

    It 'Returns the files array from the response' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            [PSCustomObject]@{ files = @('a.md', 'b.md', 'sub/') }
        }

        $result = Get-ObsidianVaultDirectory
        $result.Count | Should -Be 3
        $result | Should -Contain 'a.md'
    }
}

# =============================================================================
# SECTION 12 – Periodic Notes
# =============================================================================
Describe 'Get-ObsidianPeriodicNote' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls GET /periodic/daily/ by default' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Daily' }

        Get-ObsidianPeriodicNote

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/periodic/daily/'
        }
    }

    It 'Calls GET /periodic/weekly/ for weekly period' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Weekly' }

        Get-ObsidianPeriodicNote -Period 'weekly'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/periodic/weekly/'
        }
    }

    It 'Calls dated URI when -Date is supplied' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Past daily' }

        Get-ObsidianPeriodicNote -Period 'daily' -Date ([datetime]'2025-03-15')

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/periodic/daily/2025/3/15/'
        }
    }

    It 'Sends correct Accept header for Json format' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { [PSCustomObject]@{ content = '' } }

        Get-ObsidianPeriodicNote -Format Json

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Accept'] -eq 'application/vnd.olrapi.note+json'
        }
    }

    It 'Sends text/markdown Accept header by default' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Content' }

        Get-ObsidianPeriodicNote

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Accept'] -eq 'text/markdown'
        }
    }
}

Describe 'Set-ObsidianPeriodicNote' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls PUT /periodic/daily/ with content' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Set-ObsidianPeriodicNote -Period 'daily' -Content '# Today' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PUT' -and $Uri -like '*/periodic/daily/' -and $Body -eq '# Today'
        }
    }

    It 'Calls PUT on dated URI when -Date is supplied' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Set-ObsidianPeriodicNote -Period 'weekly' -Content '# Week' `
            -Date ([datetime]'2025-01-06') -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/periodic/weekly/2025/1/6/'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Set-ObsidianPeriodicNote -Period 'daily' -Content '# Draft' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }

    It 'Content is a mandatory parameter' {
        { Set-ObsidianPeriodicNote } | Should -Throw
    }
}

Describe 'Add-ObsidianPeriodicNoteContent' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls POST /periodic/daily/ with content' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Add-ObsidianPeriodicNoteContent -Period 'daily' -Content "`n- item"

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*/periodic/daily/'
        }
    }

    It 'Calls POST on dated URI when -Date is supplied' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Add-ObsidianPeriodicNoteContent -Period 'monthly' -Content 'text' `
            -Date ([datetime]'2025-06-01')

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/periodic/monthly/2025/6/1/'
        }
    }

    It 'Content is a mandatory parameter' {
        { Add-ObsidianPeriodicNoteContent } | Should -Throw
    }
}

Describe 'Update-ObsidianPeriodicNoteContent' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls PATCH /periodic/daily/ with Operation header' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianPeriodicNoteContent -Period 'daily' -Operation 'append' `
            -TargetType 'heading' -Target 'Tasks' -Content '- item' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'PATCH' -and
            $Uri    -like '*/periodic/daily/' -and
            $Headers['Operation'] -eq 'append'
        }
    }

    It 'Calls PATCH on dated URI when -Date is supplied' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianPeriodicNoteContent -Period 'weekly' -Date ([datetime]'2025-03-10') `
            -Operation 'prepend' -TargetType 'heading' -Target 'H1' -Content 'text' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/periodic/weekly/2025/3/10/'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianPeriodicNoteContent -Period 'daily' -Operation 'append' `
            -TargetType 'heading' -Target 'Tasks' -Content '- item' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }

    It 'Includes Create-Target-If-Missing header when switch is set' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Update-ObsidianPeriodicNoteContent -Period 'daily' -Operation 'replace' `
            -TargetType 'frontmatter' -Target 'mood' -Content '"happy"' `
            -CreateTargetIfMissing -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Headers['Create-Target-If-Missing'] -eq 'true'
        }
    }
}

Describe 'Remove-ObsidianPeriodicNote' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls DELETE /periodic/daily/' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianPeriodicNote -Period 'daily' -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'DELETE' -and $Uri -like '*/periodic/daily/'
        }
    }

    It 'Calls DELETE on dated URI when -Date is supplied' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianPeriodicNote -Period 'weekly' -Date ([datetime]'2025-01-13') -Confirm:$false

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/periodic/weekly/2025/1/13/'
        }
    }

    It 'Does NOT call the API when -WhatIf is passed' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Remove-ObsidianPeriodicNote -Period 'daily' -WhatIf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 0
    }
}

# =============================================================================
# SECTION 13 – Search
# =============================================================================
Describe 'Search-ObsidianVault' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls POST /search/ with JsonLogic content-type' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod {
            @([PSCustomObject]@{ filename = 'note.md' })
        }

        Search-ObsidianVault -Query '{"var":"tags"}' -QueryType 'JsonLogic'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method      -eq 'POST' -and
            $Uri         -like '*/search/' -and
            $ContentType -eq 'application/vnd.olrapi.jsonlogic+json'
        }
    }

    It 'Calls POST /search/ with DataviewDQL content-type' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { @() }

        Search-ObsidianVault -Query 'TABLE file.name FROM #project' -QueryType 'DataviewDQL'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $ContentType -eq 'application/vnd.olrapi.dataview.dql+txt'
        }
    }

    It 'Passes the query string as the body' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { @() }

        Search-ObsidianVault -Query 'SELECT * FROM notes' -QueryType 'DataviewDQL'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Body -eq 'SELECT * FROM notes'
        }
    }

    It 'Query and QueryType are mandatory parameters' {
        { Search-ObsidianVault -Query 'q' }              | Should -Throw
        { Search-ObsidianVault -QueryType 'JsonLogic' }  | Should -Throw
    }
}

Describe 'Search-ObsidianVaultSimple' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls POST /search/simple/ with the query parameter' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { @() }

        Search-ObsidianVaultSimple -Query 'meeting notes'

        # The Uri parameter is typed [Uri] so %20 is decoded back to a literal space
        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*/search/simple/*query=meeting notes*'
        }
    }

    It 'Includes default ContextLength of 100' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { @() }

        Search-ObsidianVaultSimple -Query 'test'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*contextLength=100*'
        }
    }

    It 'Uses custom ContextLength when supplied' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { @() }

        Search-ObsidianVaultSimple -Query 'test' -ContextLength 200

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*contextLength=200*'
        }
    }

    It 'Query is mandatory' {
        { Search-ObsidianVaultSimple } | Should -Throw
    }

    It 'ContextLength must be at least 1' {
        { Search-ObsidianVaultSimple -Query 'test' -ContextLength 0 } | Should -Throw
    }
}

# =============================================================================
# SECTION 14 – Open File
# =============================================================================
Describe 'Open-ObsidianFile' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Calls POST /open/{encodedPath}' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Open-ObsidianFile -Path 'Notes/note.md'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Method -eq 'POST' -and $Uri -like '*/open/Notes/note.md'
        }
    }

    It 'Appends ?newLeaf=true when -NewLeaf is specified' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Open-ObsidianFile -Path 'Notes/note.md' -NewLeaf

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/open/Notes/note.md?newLeaf=true'
        }
    }

    It 'Does NOT append ?newLeaf when -NewLeaf is not specified' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Open-ObsidianFile -Path 'Notes/note.md'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -notlike '*newLeaf*'
        }
    }

    It 'Passes through path with spaces' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Open-ObsidianFile -Path 'My Notes/my note.md'

        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/open/My Notes/my note.md'
        }
    }

    It 'Path is a mandatory parameter' {
        { Open-ObsidianFile } | Should -Throw
    }
}

# =============================================================================
# SECTION 15 – Cross-platform / edge-case tests
# =============================================================================
Describe 'Cross-Platform and Edge Cases' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'ConvertTo-ObsidianEncodedPath handles mixed slashes' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path 'A\B/C\note.md' |
                Should -Be 'A/B/C/note.md'
        }
    }

    It 'ConvertTo-ObsidianEncodedPath handles a leading backslash' {
        InModuleScope ObsidianLocalRestApi {
            ConvertTo-ObsidianEncodedPath -Path '\relative\path.md' |
                Should -Be '/relative/path.md'
        }
    }

    It 'Search-ObsidianVaultSimple encodes ampersand in query' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { @() }

        Search-ObsidianVaultSimple -Query 'notes & tasks'

        # [Uri] typed param decodes %20->space but keeps %26 for reserved &
        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*notes %26 tasks*'
        }
    }

    It 'Invoke-ObsidianCommand encodes colon in CommandId' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { $null }

        Invoke-ObsidianCommand -CommandId 'plugin-id:command name'

        # [Uri] decodes %20->space but %3A stays encoded for colon (reserved char)
        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/commands/plugin-id%3Acommand name/'
        }
    }

    It 'Get-ObsidianVaultFile handles deep nested path with backslashes' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# Deep note' }

        Get-ObsidianVaultFile -Path 'A\B\My Notes\deep note.md'

        # Backslashes converted to forward slashes; spaces are literal in the Uri param
        Should -Invoke -ModuleName ObsidianLocalRestApi Invoke-RestMethod -Times 1 -ParameterFilter {
            $Uri -like '*/vault/A/B/My Notes/deep note.md'
        }
    }

    It 'All five Period values are accepted by Get-ObsidianPeriodicNote' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# content' }

        foreach ($period in @('daily', 'weekly', 'monthly', 'quarterly', 'yearly')) {
            { Get-ObsidianPeriodicNote -Period $period } | Should -Not -Throw
        }
    }

    It 'All three Format values are accepted by Get-ObsidianActiveFile' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { '# content' }

        foreach ($fmt in @('Markdown', 'Json', 'DocumentMap')) {
            { Get-ObsidianActiveFile -Format $fmt } | Should -Not -Throw
        }
    }

    It 'FormatToAcceptHeader maps all three formats correctly' {
        InModuleScope ObsidianLocalRestApi {
            $script:FormatToAcceptHeader['Markdown']    | Should -Be 'text/markdown'
            $script:FormatToAcceptHeader['Json']        | Should -Be 'application/vnd.olrapi.note+json'
            $script:FormatToAcceptHeader['DocumentMap'] | Should -Be 'application/vnd.olrapi.document-map+json'
        }
    }
}

# =============================================================================
# SECTION 16 – Error handling
# =============================================================================
Describe 'Error Handling' {

    BeforeAll { Set-ObsidianTestConnection }
    AfterAll  { Clear-ObsidianTestConnection }

    It 'Propagates exception from Invoke-RestMethod to caller' {
        Mock -ModuleName ObsidianLocalRestApi Invoke-RestMethod { throw 'HTTP 404 Not Found' }

        { Get-ObsidianActiveFile } | Should -Throw '*404*'
    }

    It 'Throws Not-connected message when BaseUrl is null' {
        InModuleScope ObsidianLocalRestApi {
            $saved = $script:BaseUrl
            $script:BaseUrl = $null
            try {
                { Get-ObsidianServerStatus } | Should -Throw '*Not connected*'
            }
            finally {
                $script:BaseUrl = $saved
            }
        }
    }

    It 'Invalid Operation value for Update-ObsidianActiveFileContent throws' {
        { Update-ObsidianActiveFileContent -Operation 'upsert' -TargetType 'heading' `
              -Target 'H' -Content 'x' -Confirm:$false } | Should -Throw
    }

    It 'Invalid TargetType value throws' {
        { Update-ObsidianActiveFileContent -Operation 'append' -TargetType 'paragraph' `
              -Target 'H' -Content 'x' -Confirm:$false } | Should -Throw
    }

    It 'Invalid Period value for Get-ObsidianPeriodicNote throws' {
        { Get-ObsidianPeriodicNote -Period 'biweekly' } | Should -Throw
    }

    It 'Invalid Format value for Get-ObsidianVaultFile throws' {
        { Get-ObsidianVaultFile -Path 'note.md' -Format 'HTML' } | Should -Throw
    }

    It 'Connect-ObsidianApi throws on empty ApiKey' {
        { Connect-ObsidianApi -ApiKey '' } | Should -Throw
    }
}
