param([string]$EvidenceDirectory = 'evidence/database-cli-20260908')
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    New-Item -ItemType Directory -Force $EvidenceDirectory | Out-Null
    $cases = @(
        @{ name = 'valid'; identity = 'resolve-sidefx-eligible-providers'; input = '@examples/provider-resolution.request.json'; exit = 0 },
        @{ name = 'invalid-input'; identity = 'resolve-sidefx-eligible-providers'; input = 'null'; exit = 0 },
        @{ name = 'missing-authority'; identity = 'nonexistent-capability-for-cli-test'; input = 'null'; exit = 4 }
    )
    $records = @()
    foreach ($case in $cases) {
        $command = "sfx capability invoke $($case.identity) --input '$($case.input)' --json"
        $stdoutFile = Join-Path $EvidenceDirectory "$($case.name).stdout.json"
        $stderrFile = Join-Path $EvidenceDirectory "$($case.name).stderr.txt"
        # Windows PowerShell 5.1 rewraps redirected native stderr into formatted
        # error records; capturing 2>&1 and reading Exception.Message keeps the
        # exact JSON the CLI wrote.
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try { $output = & sfx capability invoke $case.identity --input $case.input --json 2>&1 } finally { $ErrorActionPreference = $previousPreference }
        $nativeExit = $LASTEXITCODE
        $stdout = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) -join "`n"
        $stderr = ($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.Exception.Message }) -join "`n"
        [System.IO.File]::WriteAllText($stdoutFile, $stdout)
        [System.IO.File]::WriteAllText($stderrFile, $stderr)
        $records += @{ command = $command; exitCode = $nativeExit; stdout = $stdout; stderr = $stderr }
        $records | ConvertTo-Json -Depth 100 | Set-Content -Encoding utf8 (Join-Path $EvidenceDirectory 'native-commands.json')
        if ($nativeExit -ne $case.exit) { throw "Unexpected native exit for $($case.name): $nativeExit. $stderr" }
        if ($case.name -eq 'missing-authority') {
            $failure = $stderr | ConvertFrom-Json
            if ($failure.error.code -ne 'CAPABILITY_NOT_FOUND') { throw 'Missing authority did not remain explicit.' }
            continue
        }
        $result = $stdout | ConvertFrom-Json
        if ($result.evidence.bodyStorage -ne 'MEMORY_ONLY' -or $result.evidence.authoritySource -ne 'DATABASE') { throw 'Database/memory authority evidence is missing.' }
        if ($result.evidence.process.fsWriteAllowed -ne $false -or $result.evidence.process.expandedBodyReadAllowed -ne $false -or $result.evidence.process.databaseCacheReadAllowed -ne $false) { throw 'Storage boundary was not enforced.' }
        if (@($result.evidence.modules).Count -ne 14) { throw 'Unexpected selected module closure.' }
        if (@($result.evidence.queries | Where-Object { $_.objectRetention -ne 'MEMORY_ONLY' }).Count) { throw 'Query objects were retained.' }
        if ($case.name -eq 'valid') {
            $expected = Get-Content examples/provider-resolution.request.json -Raw | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 100
            $actual = $result.result.input | ConvertTo-Json -Compress -Depth 100
            if ($actual -ne $expected) { throw 'Canonical input changed.' }
            if ($result.result.disposition -ne 'terminated' -or $result.result.outcome.disposition -ne 'PROVIDERS_RESOLVED' -or $result.result.outcome.consideredCount -ne 2 -or $result.result.outcome.eligibleCount -ne 1) { throw 'Provider resolution outcome diverged.' }
        } elseif ($result.result.disposition -ne 'rejected') { throw 'Invalid input was not rejected by the capability.' }
    }
    Write-Output "PASSED: three native sfx invocations; exact commands, exits and streams retained in $EvidenceDirectory."
} finally { Pop-Location }
