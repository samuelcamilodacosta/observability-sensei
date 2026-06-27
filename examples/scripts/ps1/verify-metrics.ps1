param(
  [string]$MetricsUrl = "http://localhost:3000/metrics",
  [double]$MaxErrorRate = 0.05
)

function Log($msg) { Write-Host "[verify-metrics] $(Get-Date -Format o) $msg" }

Log "Fetching metrics from: $MetricsUrl"
$body = (Invoke-WebRequest -Uri $MetricsUrl -UseBasicParsing).Content

if ($body -notmatch 'http_requests_total') {
  Log "FAIL: http_requests_total not found"
  exit 1
}

$reqMatches = [regex]::Matches($body, '(?m)^http_requests_total(?:\{[^}]*\})?\s+(\d+(?:\.\d+)?)')
$errMatches = [regex]::Matches($body, '(?m)^http_request_errors_total(?:\{[^}]*\})?\s+(\d+(?:\.\d+)?)')

$totalReq = ($reqMatches | ForEach-Object { [double]$_.Groups[1].Value } | Measure-Object -Sum).Sum
$totalErr = ($errMatches | ForEach-Object { [double]$_.Groups[1].Value } | Measure-Object -Sum).Sum
if ($null -eq $totalReq) { $totalReq = 0 }
if ($null -eq $totalErr) { $totalErr = 0 }

$errorRate = if ($totalReq -gt 0) { $totalErr / $totalReq } else { 0 }
Log "Total requests: $totalReq | errors: $totalErr | rate: $errorRate"

if ($errorRate -le $MaxErrorRate) {
  Log "OK: error rate within threshold"
  exit 0
}
Log "FAIL: error rate exceeds $MaxErrorRate"
exit 1
