# demo.ps1 - Quickstart for Windows (PowerShell)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Log($msg) { Write-Host "[demo] $msg" }

function ConvertTo-GitBashPath([string]$Path) {
    $normalized = $Path -replace '\\', '/'
    if ($normalized -match '^([A-Za-z]):(/.*|$)') {
        return ('/' + $Matches[1].ToLower() + $Matches[2])
    }
    return $normalized
}

Log "Starting observability stack..."
docker compose up -d --build

Log "Waiting for API health..."
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $h = Invoke-RestMethod http://localhost:3000/health -ErrorAction Stop
        if ($h.status -eq "ok") { $ready = $true; break }
    } catch {
        # API still starting
    }
    Start-Sleep -Seconds 2
}
if (-not $ready) {
    Write-Warning "API not ready yet - check: docker compose logs api"
}

Log "Generating sample traffic..."
1..15 | ForEach-Object { Invoke-RestMethod http://localhost:3000/api/example | Out-Null }

Log "Running Production Gate..."
$ps1Gate = Join-Path $Root "examples\scripts\ps1\production-gate.ps1"
if (Test-Path $ps1Gate) {
    & $ps1Gate -SoakSeconds 2
} elseif (Get-Command bash -ErrorAction SilentlyContinue) {
    $bashRoot = ConvertTo-GitBashPath $Root
    $bashCmd = "cd '$bashRoot' && GATE_SOAK_SECONDS=2 ./examples/scripts/production-gate.sh"
    bash -c $bashCmd
} else {
    Write-Warning "Production Gate skipped - no PowerShell or bash scripts found"
}

Write-Host ""
Write-Host "============================================"
Write-Host "  observability-sensei - stack ready"
Write-Host "============================================"
Write-Host "  API:        http://localhost:3000/health"
Write-Host "  Prometheus: http://localhost:9090/targets"
Write-Host "  Grafana:    http://localhost:3001  (admin / sensei)"
Write-Host "  Loki:       Grafana Explore -> datasource Loki"
Write-Host "  Jaeger:     http://localhost:16686"
Write-Host "  Labs:       docs/labs/"
Write-Host "  Docs (PT):  docs/pt/README.md"
Write-Host "============================================"
