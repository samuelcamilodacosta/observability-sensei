param(
  [string]$HealthUrl = "http://localhost:3000/health",
  [string]$MetricsUrl = "http://localhost:3000/metrics",
  [int]$SoakSeconds = 3,
  [int]$MaxLatencyMs = 500
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "[production-gate] Soak ${SoakSeconds}s..."
Start-Sleep -Seconds $SoakSeconds

$failed = $false
$baseUrl = $HealthUrl -replace '/health/?$', ''

Write-Host "[production-gate] Step 1/3: Health"
& "$ScriptDir\health-check.ps1" -HealthUrl $HealthUrl
if ($LASTEXITCODE -ne 0) { $failed = $true }

Write-Host "[production-gate] Step 2/3: Metrics"
& "$ScriptDir\verify-metrics.ps1" -MetricsUrl $MetricsUrl
if ($LASTEXITCODE -ne 0) { $failed = $true }

Write-Host "[production-gate] Step 3/3: Latency"
try {
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  Invoke-RestMethod "$baseUrl/api/example" -TimeoutSec 10 | Out-Null
  $sw.Stop()
  $ms = $sw.ElapsedMilliseconds
  if ($ms -gt $MaxLatencyMs) {
    Write-Host "[production-gate] FAIL: latency ${ms}ms exceeds ${MaxLatencyMs}ms"
    $failed = $true
  } else {
    Write-Host "[production-gate] OK: latency ${ms}ms"
  }
} catch {
  Write-Host "[production-gate] FAIL: latency probe error"
  $failed = $true
}

if ($failed) {
  Write-Host "[production-gate] ROLLBACK"
  exit 1
}
Write-Host "[production-gate] PROMOTE"
exit 0
