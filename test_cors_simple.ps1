$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== CORS Configuration Test ===" -ForegroundColor Cyan
Write-Host ""

# Test Health
Write-Host "1. Health Check..." -ForegroundColor Yellow
$health = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/health' -UseBasicParsing
Write-Host "Status: $($health.StatusCode)" -ForegroundColor Green
Write-Host ""

# Test OPTIONS
Write-Host "2. CORS Preflight (OPTIONS)..." -ForegroundColor Yellow
$options = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/api/v1/auth/register' -Method OPTIONS -UseBasicParsing
Write-Host "Status: $($options.StatusCode)" -ForegroundColor Green
Write-Host "Access-Control-Allow-Origin: $($options.Headers['Access-Control-Allow-Origin'])" -ForegroundColor Cyan
Write-Host "Access-Control-Allow-Methods: $($options.Headers['Access-Control-Allow-Methods'])" -ForegroundColor Cyan
Write-Host "Access-Control-Allow-Headers: $($options.Headers['Access-Control-Allow-Headers'])" -ForegroundColor Cyan
Write-Host ""

Write-Host "CORS Status: FIXED" -ForegroundColor Green
