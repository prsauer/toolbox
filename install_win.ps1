$scriptRoot = $PSScriptRoot
$manifestPath = Join-Path $scriptRoot "manifest.json"

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

foreach ($pair in $manifest.windows.copy) {
    $src = Join-Path $scriptRoot $pair[0]
    $dst = $pair[1]
    
    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
    }
    
    Copy-Item $src -Destination $dst -Force
    Write-Host "Copied $($pair[0]) -> $dst" -ForegroundColor Green
}

foreach ($alias in $manifest.windows.alias) {
    Write-Host "Alias: $alias" -ForegroundColor Cyan
}

Write-Host "Done!" -ForegroundColor Green
