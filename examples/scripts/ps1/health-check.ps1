param(
  [string]$HealthUrl = "http://localhost:3000/health",
  [int]$MaxRetries = 10,
  [int]$RetryInterval = 3
)

function Log($msg) { Write-Host "[health-check] $(Get-Date -Format o) $msg" }

for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
  Log "Attempt $attempt/$MaxRetries"
  try {
    $r = Invoke-WebRequest -Uri $HealthUrl -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -eq 200 -and $r.Content -match '"status"\s*:\s*"ok"') {
      Log "OK: health check passed"
      Write-Output $r.Content
      exit 0
    }
  } catch {}
  if ($attempt -lt $MaxRetries) { Start-Sleep -Seconds $RetryInterval }
}

Log "FAIL: health check exhausted all retries"
exit 1
