# Install English Responses into the current project for all Skills CLI agents.
# PowerShell 5.1+; requires Git and Node.js 22.20+ (including npx).
[CmdletBinding()]
param(
    [string]$Project = (Get-Location).Path,
    [string]$CacheRoot,
    [string]$Source = 'Tavneet-18/english-responses'
)

$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path -LiteralPath $Project -ErrorAction Stop).Path
if (-not (Test-Path -LiteralPath $projectPath -PathType Container)) {
    throw 'Project must be an existing directory.'
}

$null = Get-Command git -ErrorAction Stop
$null = Get-Command node -ErrorAction Stop
$npxCommand = Get-Command npx.cmd -ErrorAction SilentlyContinue
if (-not $npxCommand) { $npxCommand = Get-Command npx -ErrorAction Stop }
$nodeVersion = (& node --version).Trim().TrimStart('v')
if ($LASTEXITCODE -ne 0 -or [version]$nodeVersion -lt [version]'22.20.0') {
    throw 'Node.js 22.20.0 or newer is required. No runtime is installed automatically.'
}

if (-not $CacheRoot) {
    if (Test-Path -LiteralPath 'D:\opencode_works' -PathType Container) {
        $CacheRoot = 'D:\opencode_works\.english-responses-tools'
    } else {
        $CacheRoot = Join-Path $projectPath '.english-responses-tools'
    }
}
$cachePath = [System.IO.Path]::GetFullPath($CacheRoot)
$npmCache = Join-Path $cachePath 'npm-cache'
$tempPath = Join-Path $cachePath 'temp'
$statePath = Join-Path $cachePath 'state'
foreach ($directory in @($npmCache, $tempPath, $statePath)) {
    $null = New-Item -ItemType Directory -Force -Path $directory
}

# Scope changes to this script and restore every process environment value.
$overrides = @{
    'npm_config_cache' = $npmCache
    'TMP' = $tempPath
    'TEMP' = $tempPath
    'TMPDIR' = $tempPath
    'XDG_STATE_HOME' = $statePath
    'DISABLE_TELEMETRY' = '1'
    'DO_NOT_TRACK' = '1'
}
$previous = @{}
foreach ($key in $overrides.Keys) {
    $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
}
$pushedLocation = $false
try {
    foreach ($key in $overrides.Keys) {
        [Environment]::SetEnvironmentVariable($key, $overrides[$key], 'Process')
    }
    Push-Location -LiteralPath $projectPath
    $pushedLocation = $true
    Write-Host "Installing English Responses into $projectPath"
    Write-Host "Downloads, temporary files, and CLI state: $cachePath"
    & $npxCommand.Source --yes --cache $npmCache skills@1.7.6 add $Source --skill english-responses --agent '*' --yes --copy
    if ($LASTEXITCODE -ne 0) { throw "Skills CLI failed with exit code $LASTEXITCODE." }
    if (-not (Test-Path -LiteralPath (Join-Path $projectPath '.agents/skills/english-responses/SKILL.md'))) {
        throw 'Skills CLI did not create the expected skill file.'
    }
    Write-Host ''
    Write-Host 'Installed. Reload skills or start a fresh agent session in this project.'
    Write-Host 'Ask: Use english-responses for English-only messages throughout this task and pass it to delegated agents.'
} finally {
    if ($pushedLocation) { Pop-Location }
    foreach ($key in $previous.Keys) {
        if ($null -eq $previous[$key]) {
            Remove-Item -LiteralPath "Env:\$key" -ErrorAction SilentlyContinue
        } else {
            [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process')
        }
    }
}
