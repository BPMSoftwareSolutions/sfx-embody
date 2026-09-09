param(
    [ValidateSet('Prepare','PrepareExplicit','Invoke','AnyCapability')][string]$Mode = 'Invoke',
    [string]$EvidenceDirectory = 'evidence/database-preparation-20260908'
)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    New-Item -ItemType Directory -Force $EvidenceDirectory | Out-Null
    function Invoke-NativeCase($Name, $Arguments, $ExpectedExit) {
        $stdoutFile = Join-Path $EvidenceDirectory "$Name.stdout.json"
        $stderrFile = Join-Path $EvidenceDirectory "$Name.stderr.txt"
        $watch = [Diagnostics.Stopwatch]::StartNew()
        # Windows PowerShell 5.1 rewraps redirected native stderr into formatted
        # error records; capturing 2>&1 and reading Exception.Message keeps the
        # exact JSON the CLI wrote.
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try { $output = & sfx @Arguments 2>&1 } finally { $ErrorActionPreference = $previousPreference }
        $nativeExit = $LASTEXITCODE
        $watch.Stop()
        $rendered = $Arguments | ForEach-Object { if ($_ -match '[\s@\x27]') { "'" + $_.Replace("'", "''") + "'" } else { $_ } }
        $stdout = ($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }) -join "`n"
        $stderr = ($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { $_.Exception.Message }) -join "`n"
        [System.IO.File]::WriteAllText($stdoutFile, $stdout)
        [System.IO.File]::WriteAllText($stderrFile, $stderr)
        $record = [ordered]@{ command = 'sfx ' + ($rendered -join ' '); arguments = $Arguments; exitCode = $nativeExit; elapsedMs = $watch.Elapsed.TotalMilliseconds;
            stdout = $stdout; stderr = $stderr }
        $record | ConvertTo-Json -Depth 100 | Set-Content -Encoding utf8 (Join-Path $EvidenceDirectory "$Name.command.json")
        if ($nativeExit -ne $ExpectedExit) { throw "Unexpected exit $nativeExit for $Name. $stderr" }
        if ($nativeExit -eq 0) { return ($stdout | ConvertFrom-Json) }
        return ($stderr | ConvertFrom-Json)
    }
    $invoke = @('capability','invoke','resolve-sidefx-eligible-providers','--input','@examples/provider-resolution.request.json','--json')
    if ($Mode -in @('Prepare','PrepareExplicit')) {
        $prepareArgs = @('capability','prepare','resolve-sidefx-eligible-providers','--timeout','600000','--json')
        $caseName = 'prepare'
        if ($Mode -eq 'PrepareExplicit') { $prepareArgs += @('--namespace','sidefx:capabilities'); $caseName = 'prepare-explicit' }
        $result = Invoke-NativeCase $caseName $prepareArgs 0
        if ($result.disposition -ne 'CAPABILITY_PREPARED' -or $result.proof.fixtureCount -ne 4 -or $result.proof.assertionCount -ne 28) { throw 'Preparation proof diverged.' }
        if ($Mode -eq 'PrepareExplicit' -and $result.status -ne 'ALREADY_PREPARED') { throw 'Explicit namespace changed an identical preparation.' }
        if ($result.evidence.bodyStorage -ne 'MEMORY_ONLY' -or $result.evidence.process.fsWriteAllowed -ne $false) { throw 'Preparation storage boundary failed.' }
        $result | Select-Object disposition, preparationDigest, status, byteLength, @{n='timings';e={$_.evidence.timings}} | ConvertTo-Json -Depth 10
    } elseif ($Mode -eq 'AnyCapability') {
        # Direct invocation resolves and executes any selected capability; a stored
        # preparation is neither required nor consulted. Null input reaches the
        # capability contract and returns its rejected disposition.
        $result = Invoke-NativeCase 'any-capability' @('capability','invoke','adapt-job-market-intelligence-evidence','--input','null','--json') 0
        if ($result.result.disposition -ne 'rejected') { throw 'Null input was not rejected by the capability.' }
        if ($result.evidence.bodyStorage -ne 'MEMORY_ONLY' -or $result.evidence.authoritySource -ne 'DATABASE') { throw 'Direct invocation evidence diverged.' }
        Write-Output 'PASSED: any selected capability invokes directly; contract rejection is carried through.'
    } else {
        $result = Invoke-NativeCase 'direct-invoke' $invoke 0
        if ($result.result.outcome.disposition -ne 'PROVIDERS_RESOLVED' -or $result.result.outcome.consideredCount -ne 2 -or $result.result.outcome.eligibleCount -ne 1) { throw 'Invocation outcome diverged.' }
        $queryNames = @($result.evidence.timings.queries.PSObject.Properties | ForEach-Object { $_.Name })
        if ($queryNames.Count -ne 3 -or $queryNames -notcontains 'capability-embodiment.sql' -or $queryNames -notcontains 'scenario-resolver-map.sql' -or $queryNames -notcontains 'mechanic-definitions.sql') { throw 'Invocation did not resolve authority, requirements and mechanics directly.' }
        if (@($result.evidence.queries | Where-Object { $_.objectRetention -ne 'MEMORY_ONLY' }).Count) { throw 'Query objects were retained.' }
        if ($result.evidence.process.fsWriteAllowed -ne $false -or $result.evidence.process.expandedBodyReadAllowed -ne $false -or $result.evidence.process.databaseCacheReadAllowed -ne $false) { throw 'Invocation storage boundary failed.' }
        $expected = Get-Content examples/provider-resolution.request.json -Raw | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 100
        if (($result.result.input | ConvertTo-Json -Compress -Depth 100) -ne $expected) { throw 'Canonical input changed.' }
        $result.evidence.timings | ConvertTo-Json -Depth 10
    }
} finally { Pop-Location }
