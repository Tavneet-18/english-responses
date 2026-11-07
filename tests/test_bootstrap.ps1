# Integration test: runs the real pinned CLI against local skill content.
$ErrorActionPreference = 'Stop'
$repoPath = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $repoPath ('.tmp/bootstrap-' + [guid]::NewGuid().ToString('N'))
$projectPath = Join-Path $testRoot 'project'
$multiAgentProject = Join-Path $testRoot 'multi-agent-project'
$emptySource = Join-Path $testRoot 'empty-source'
$failureProject = Join-Path $testRoot 'failure-project'
foreach ($directory in @($projectPath, $multiAgentProject, $emptySource, $failureProject)) {
    $null = New-Item -ItemType Directory -Force -Path $directory
}
$savedEnv = @{}
foreach ($name in @('TEMP', 'TMP', 'TMPDIR', 'npm_config_cache', 'XDG_STATE_HOME', 'DISABLE_TELEMETRY', 'DO_NOT_TRACK')) {
    $savedEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
}

function Assert-EnvironmentRestored {
    foreach ($name in $savedEnv.Keys) {
        $current = [Environment]::GetEnvironmentVariable($name, 'Process')
        if ($null -eq $savedEnv[$name]) {
            if ($null -ne $current) { throw "Previously unset variable remains: $name" }
        } elseif ($current -cne $savedEnv[$name]) {
            throw "Environment variable changed: $name"
        }
    }
}

$cachePath = Join-Path $repoPath '.tmp'
$installer = Join-Path $repoPath 'install.ps1'
$locationBefore = (Get-Location).Path
& $installer -Project $projectPath -CacheRoot $cachePath -Source $repoPath *> (Join-Path $testRoot 'install.log')
Assert-EnvironmentRestored
if ((Get-Location).Path -ne $locationBefore) { throw 'Working directory changed.' }
$expected = (Get-FileHash -LiteralPath (Join-Path $repoPath 'skills/english-responses/SKILL.md')).Hash
foreach ($relative in @('.agents/skills/english-responses/SKILL.md')) {
    if ((Get-FileHash -LiteralPath (Join-Path $projectPath $relative)).Hash -ne $expected) {
        throw "Installed skill content differs: $relative"
    }
}
if (@(Get-ChildItem -LiteralPath $projectPath -Directory -Force | Where-Object Name -ne '.agents').Count -ne 0) {
    throw 'Default installation created extra agent folders.'
}
if (-not (Test-Path -LiteralPath (Join-Path $projectPath 'skills-lock.json'))) {
    throw 'Project skill lock was not created.'
}

# Agent-specific folders are created only when explicitly requested.
& $installer -Project $multiAgentProject -CacheRoot $cachePath -Source $repoPath -Agent @('universal', 'claude-code', 'roo') *> (Join-Path $testRoot 'multi-agent.log')
Assert-EnvironmentRestored
foreach ($relative in @('.claude/skills/english-responses/SKILL.md', '.roo/skills/english-responses/SKILL.md')) {
    if ((Get-FileHash -LiteralPath (Join-Path $multiAgentProject $relative)).Hash -ne $expected) {
        throw "Explicit agent installation differs: $relative"
    }
}

# A source with no skills must fail, while still restoring the caller's state.
$failureCaught = $false
try {
    & $installer -Project $failureProject -CacheRoot $cachePath -Source $emptySource *> (Join-Path $testRoot 'failure.log')
} catch {
    $failureCaught = $true
}
if (-not $failureCaught) { throw 'Empty skill source unexpectedly succeeded.' }
Assert-EnvironmentRestored
if ((Get-Location).Path -ne $locationBefore) { throw 'Failure changed working directory.' }
Write-Output 'Bootstrap integration passed: compact default, explicit agent targets, failure handling, environment and working-directory restoration.'
Write-Output "Logs: $testRoot"
# The expected CLI failure above leaves LASTEXITCODE nonzero. Report the test
# result explicitly so CI does not mistake that intentional failure for ours.
exit 0
