# 🚀 Build Android APK Helper Script
# Skrip ini membantu build APK dengan konfigurasi optimal

Write-Host "🐠 Aquarium Monitor - Android Build Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Function untuk clean build
function Clean-Build {
    Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
    
    # Stop Gradle daemons
    Push-Location android
    .\gradlew --stop 2>$null
    Pop-Location
    
    # Clean Flutter
    flutter clean
    
    # Remove Gradle build folders
    Remove-Item -Recurse -Force "android\.gradle" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "android\app\build" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "build" -ErrorAction SilentlyContinue
    
    Write-Host "✅ Clean completed!" -ForegroundColor Green
    Write-Host ""
}

# Function untuk build debug APK
function Build-Debug {
    Write-Host "🔨 Building Debug APK..." -ForegroundColor Yellow
    Write-Host ""
    
    flutter pub get
    flutter build apk --debug --no-shrink
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Build SUCCESS!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📦 APK Location:" -ForegroundColor Cyan
        Write-Host "   build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor White
        Write-Host ""
        
        # Show APK size
        $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
        if (Test-Path $apkPath) {
            $size = (Get-Item $apkPath).Length / 1MB
            Write-Host "📊 APK Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
        }
    } else {
        Write-Host ""
        Write-Host "❌ Build FAILED!" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 Try running: .\build-android.ps1 -Clean" -ForegroundColor Yellow
    }
}

# Function untuk build release APK
function Build-Release {
    Write-Host "🔨 Building Release APK..." -ForegroundColor Yellow
    Write-Host ""
    
    flutter pub get
    flutter build apk --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Build SUCCESS!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📦 APK Location:" -ForegroundColor Cyan
        Write-Host "   build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor White
        Write-Host ""
        
        # Show APK size
        $apkPath = "build\app\outputs\flutter-apk\app-release.apk"
        if (Test-Path $apkPath) {
            $size = (Get-Item $apkPath).Length / 1MB
            Write-Host "📊 APK Size: $([math]::Round($size, 2)) MB" -ForegroundColor Cyan
        }
    } else {
        Write-Host ""
        Write-Host "❌ Build FAILED!" -ForegroundColor Red
    }
}

# Function untuk install APK ke device
function Install-APK {
    Write-Host "📱 Installing APK to connected device..." -ForegroundColor Yellow
    Write-Host ""
    
    flutter install
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Installation SUCCESS!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Installation FAILED!" -ForegroundColor Red
        Write-Host "💡 Make sure device is connected and USB debugging is enabled" -ForegroundColor Yellow
    }
}

# Function untuk run di device
function Run-OnDevice {
    Write-Host "🚀 Running app on connected device..." -ForegroundColor Yellow
    Write-Host ""
    
    flutter run --release
}

# Main menu
param(
    [switch]$Clean,
    [switch]$Debug,
    [switch]$Release,
    [switch]$Install,
    [switch]$Run,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\build-android.ps1 -Clean     # Clean build cache" -ForegroundColor White
    Write-Host "  .\build-android.ps1 -Debug     # Build debug APK" -ForegroundColor White
    Write-Host "  .\build-android.ps1 -Release   # Build release APK" -ForegroundColor White
    Write-Host "  .\build-android.ps1 -Install   # Install APK to device" -ForegroundColor White
    Write-Host "  .\build-android.ps1 -Run       # Run app on device" -ForegroundColor White
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\build-android.ps1 -Clean -Debug  # Clean then build debug" -ForegroundColor White
    Write-Host ""
    exit
}

# Execute commands
if ($Clean) {
    Clean-Build
}

if ($Debug) {
    Build-Debug
}

if ($Release) {
    Build-Release
}

if ($Install) {
    Install-APK
}

if ($Run) {
    Run-OnDevice
}

# If no parameters, show menu
if (-not ($Clean -or $Debug -or $Release -or $Install -or $Run)) {
    Write-Host "Select build option:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Build Debug APK" -ForegroundColor White
    Write-Host "2. Build Release APK" -ForegroundColor White
    Write-Host "3. Clean Build" -ForegroundColor White
    Write-Host "4. Install to Device" -ForegroundColor White
    Write-Host "5. Run on Device" -ForegroundColor White
    Write-Host "6. Clean + Build Debug" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter choice (1-6)"
    
    switch ($choice) {
        "1" { Build-Debug }
        "2" { Build-Release }
        "3" { Clean-Build }
        "4" { Install-APK }
        "5" { Run-OnDevice }
        "6" { 
            Clean-Build
            Build-Debug
        }
        default {
            Write-Host "Invalid choice!" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Done! 🎉" -ForegroundColor Green
