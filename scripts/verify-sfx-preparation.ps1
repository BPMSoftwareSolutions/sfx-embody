param(
    [ValidateSet('Prepare','PrepareExplicit','Invoke','Stale','Unprepared')][string]$Mode = 'Invoke',
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
        & sfx @Arguments 1> $stdoutFile 2> $stderrFile
        $nativeExit = $LASTEXITCODE
        $watch.Stop()
        $rendered = $Arguments | ForEach-Object { if ($_ -match '[\s@\x27]') { "'" + $_.Replace("'", "''") + "'" } else { $_ } }
        $record = [ordered]@{ command = 'sfx ' + ($rendered -join ' '); arguments = $Arguments; exitCode = $nativeExit; elapsedMs = $watch.Elapsed.TotalMilliseconds;
            stdout = [IO.File]::ReadAllText((Resolve-Path $stdoutFile)); stderr = [IO.File]::ReadAllText((Resolve-Path $stderrFile)) }
        $record | ConvertTo-Json -Depth 100 | Set-Content -Encoding utf8 (Join-Path $EvidenceDirectory "$Name.command.json")
        if ($nativeExit -ne $ExpectedExit) { throw "Unexpected exit $nativeExit for $Name. $($record.stderr)" }
        if ($nativeExit -eq 0) { return ($record.stdout | ConvertFrom-Json) }
        return ($record.stderr | ConvertFrom-Json)
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
    } elseif ($Mode -eq 'Unprepared') {
        $result = Invoke-NativeCase 'unprepared' @('capability','invoke','adapt-job-market-intelligence-evidence','--input','null','--json') 4
        if ($result.error.code -ne 'CAPABILITY_PREPARATION_REQUIRED') { throw 'Missing preparation was not explicit.' }
        Write-Output 'PASSED: unprepared capability rejects without analysis.'
    } elseif ($Mode -eq 'Stale') {
        $config = Get-Content config/database-runtime.json -Raw | ConvertFrom-Json
        $database = [IO.Path]::GetFullPath((Join-Path (Resolve-Path config) $config.databaseRoot))
        $recipeFile = Join-Path $database 'sql/runtime/read-preparation.sql'
        $originalBytes = [IO.File]::ReadAllBytes($recipeFile)
        try {
            [IO.File]::AppendAllText($recipeFile, "`n-- Native acceptance: changed resolver recipe identity.`n")
            $result = Invoke-NativeCase 'stale-recipe' $invoke 4
            if ($result.error.code -ne 'CAPABILITY_PREPARATION_STALE') { throw 'Changed recipe did not invalidate preparation.' }
        } finally { [IO.File]::WriteAllBytes($recipeFile, $originalBytes) }
        Write-Output 'PASSED: changed recipe rejected; original bytes restored.'
    } else {
        $result = Invoke-NativeCase 'prepared-invoke' $invoke 0
        if ($result.result.outcome.disposition -ne 'PROVIDERS_RESOLVED' -or $result.result.outcome.consideredCount -ne 2 -or $result.result.outcome.eligibleCount -ne 1) { throw 'Invocation outcome diverged.' }
        if (@($result.evidence.queries).Count -ne 1 -or $result.evidence.queries[0].objectRetention -ne 'MEMORY_ONLY') { throw 'Invocation must perform one unretained lookup.' }
        if ($result.evidence.timings.queries.'scenario-resolver-map.sql') { throw 'Invocation ran the resolver analysis.' }
        if ($result.evidence.process.fsWriteAllowed -ne $false -or $result.evidence.process.expandedBodyReadAllowed -ne $false -or $result.evidence.process.databaseCacheReadAllowed -ne $false) { throw 'Invocation storage boundary failed.' }
        $expected = Get-Content examples/provider-resolution.request.json -Raw | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 100
        if (($result.result.input | ConvertTo-Json -Compress -Depth 100) -ne $expected) { throw 'Canonical input changed.' }
        $result.evidence.timings | ConvertTo-Json -Depth 10
    }
} finally { Pop-Location }
