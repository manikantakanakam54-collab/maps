# Deploy LPU Maps to Vercel
Write-Host "Building Flutter Web release..." -ForegroundColor Cyan
& "C:\src\flutter\bin\flutter.bat" build web --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Flutter web build failed." -ForegroundColor Red
    exit 1
}

Write-Host "Deploying to Vercel..." -ForegroundColor Green
npx vercel deploy build/web --prod
