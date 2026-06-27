# generate-traffic.ps1 - Generate sample requests for dashboards and gate testing
param(
    [string]$BaseUrl = "http://localhost:3000",
    [int]$Ok = 20,
    [int]$Errors = 0,
    [int]$Slow = 0,
    [int]$DelayMs = 50
)

$ErrorActionPreference = "Continue"

function Log($msg) {
    Write-Host "[generate-traffic] $(Get-Date -Format o) $msg"
}

function Test-ApiReachable([string]$Url) {
    try {
        Invoke-RestMethod "$Url/health" -TimeoutSec 5 | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Invoke-TrafficRequest([string]$Url, [string]$Label) {
    try {
        Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30 | Out-Null
        Log "  OK   $Label"
    } catch {
        Log "  FAIL $Label (expected for /error)"
    }
    if ($DelayMs -gt 0) { Start-Sleep -Milliseconds $DelayMs }
}

$BaseUrl = $BaseUrl.TrimEnd('/')

if (-not (Test-ApiReachable $BaseUrl)) {
    Log "WARN: API not reachable at $BaseUrl/health - continuing anyway"
}

Log "Target: $BaseUrl"
Log "Plan: ok=$Ok errors=$Errors slow=$Slow delay=${DelayMs}ms"

if ($Ok -gt 0) {
    Log "Sending $Ok successful requests..."
    for ($i = 1; $i -le $Ok; $i++) {
        Invoke-TrafficRequest "$BaseUrl/api/example" "GET /api/example ($i/$Ok)"
    }
}

if ($Errors -gt 0) {
    Log "Sending $Errors error requests..."
    for ($i = 1; $i -le $Errors; $i++) {
        Invoke-TrafficRequest "$BaseUrl/api/example/error" "GET /api/example/error ($i/$Errors)"
    }
}

if ($Slow -gt 0) {
    Log "Sending $Slow slow requests..."
    for ($i = 1; $i -le $Slow; $i++) {
        Invoke-TrafficRequest "$BaseUrl/api/example/slow" "GET /api/example/slow ($i/$Slow)"
    }
}

Log "Done. Open Grafana http://localhost:3001 or Prometheus http://localhost:9090"
