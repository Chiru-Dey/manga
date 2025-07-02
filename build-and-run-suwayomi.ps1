# --- Automatically set execution policy for this process ---
if ((Get-ExecutionPolicy -Scope Process) -ne "Bypass") {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
}

# --- Configuration ---
$SUWAYOMI_SERVER_DIR = "Suwayomi-Server"
$SUWAYOMI_WEBUI_DIR = "Suwayomi-WebUI"
$CUSTOM_DATA_ROOT = Join-Path -Path (Get-Location) -ChildPath "suwayomi-data"
$CUSTOM_WEBUI_TARGET_DIR = Join-Path -Path $CUSTOM_DATA_ROOT -ChildPath "webUI"
$SERVER_CONF_FILE = Join-Path -Path $CUSTOM_DATA_ROOT -ChildPath "server.conf"

# --- Ensure Execution Policy ---
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# --- Function: Check Java version ---
function Find-JavaAndCheckVersion {
    $requiredVersion = 21
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue

    if (-not $javaCmd) {
        Write-Error "Java executable not found. Please ensure Java is installed and in your PATH."
        exit 1
    }

    $javaVersionOutput = & java -version 2>&1
    $versionLine = ($javaVersionOutput | Select-String -Pattern 'version').Line
    if ($versionLine -match '"([\d._]+)"') {
        $javaVersion = $matches[1]
    } else {
        Write-Error "Unable to parse Java version."
        exit 1
    }

    $majorVersion = ($javaVersion -split '\.')[0]
    if ($majorVersion -eq "1") {
        $majorVersion = ($javaVersion -split '\.')[1]
    }

    Write-Output "Detected Java version: $javaVersion (Major: $majorVersion)"

    if ([int]$majorVersion -lt $requiredVersion) {
        Write-Error "Suwayomi-Server requires Java $requiredVersion or higher."
        exit 1
    }
    Write-Output "Java version OK."
}

# --- Kill any running server processes ---
Write-Output "Stopping any running Suwayomi-Server processes..."
Get-Process java -ErrorAction SilentlyContinue | Where-Object {
    $_.Path -and ($_.Path -match "Suwayomi-Server")
} | Stop-Process -Force

# --- Check Java ---
Find-JavaAndCheckVersion

# --- Build Suwayomi-Server ---
Write-Output "Building Suwayomi-Server..."
Push-Location $SUWAYOMI_SERVER_DIR
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "server\build"

& .\gradlew.bat shadowJar
if ($LASTEXITCODE -ne 0) {
    Write-Error "Suwayomi-Server build failed!"
    exit 1
}

$serverJar = Get-ChildItem -Path "server\build" -Filter "Suwayomi-Server-*.jar" -Recurse | Select-Object -First 1
if (-not $serverJar) {
    Write-Error "Suwayomi-Server JAR not found!"
    exit 1
}
$SERVER_JAR_ABSOLUTE_PATH = $serverJar.FullName
Write-Output "Suwayomi-Server JAR built: $SERVER_JAR_ABSOLUTE_PATH"
Pop-Location

# --- Build Suwayomi-WebUI ---
Write-Output "Building Suwayomi-WebUI..."
Push-Location $SUWAYOMI_WEBUI_DIR

# Ensure the correct Node version
$nvmPath = "$env:APPDATA\nvm\nvm.exe"
if (Test-Path $nvmPath) {
    & $nvmPath use 22.12.0
} else {
    Write-Warning "nvm not found. Make sure Node.js 22.12.0 is active."
}

# Install dependencies
yarn install
if ($LASTEXITCODE -ne 0) {
    Write-Error "yarn install failed!"
    exit 1
}

# Verify vite
npx vite --version
if ($LASTEXITCODE -ne 0) {
    Write-Warning "vite not found or broken."
}

# Build WebUI
yarn build
if ($LASTEXITCODE -ne 0) {
    Write-Error "Suwayomi-WebUI build failed!"
    exit 1
}

$WEBUI_BUILD_DIR = Join-Path (Get-Location) "build"
Write-Output "Suwayomi-WebUI built: $WEBUI_BUILD_DIR"
Pop-Location

# --- Prepare data directory ---
Write-Output "Preparing custom data directory..."
Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $CUSTOM_DATA_ROOT
New-Item -ItemType Directory -Path $CUSTOM_WEBUI_TARGET_DIR -Force | Out-Null
Copy-Item -Recurse -Force "$WEBUI_BUILD_DIR\*" "$CUSTOM_WEBUI_TARGET_DIR\"
Write-Output "WebUI copied to: $CUSTOM_WEBUI_TARGET_DIR"

# --- Determine WebUI access URL ---
$SERVER_IP = "localhost"
$SERVER_PORT = "8080"
if (Test-Path $SERVER_CONF_FILE) {
    $conf = Get-Content $SERVER_CONF_FILE
    if (($conf | Select-String 'ip\s*=').Line -match '"(.*?)"') {
        $ipVal = $matches[1]
        if ($ipVal -eq "0.0.0.0") {
            $SERVER_IP = "localhost"
        } else {
            $SERVER_IP = $ipVal
        }
    }
    if (($conf | Select-String 'port\s*=').Line -match 'port\s*=\s*(\d+)') {
        $SERVER_PORT = $matches[1]
    }
}

Write-Output ""
Write-Output "🚀 Starting Suwayomi-Server..."
Write-Output "🌐 Access at: http://$SERVER_IP`:$SERVER_PORT"
Write-Output ""

# --- Launch Server ---
& java `
    -Djava.awt.headless=true `
    -Dcef.headless=true `
    "-Dsuwayomi.tachidesk.config.server.rootDir=$CUSTOM_DATA_ROOT" `
    "-Dsuwayomi.tachidesk.config.server.webUIFlavor=CUSTOM" `
    "-Dsuwayomi.tachidesk.config.server.webUI.autoDownload=false" `
    "-Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false" `
    "-Dsuwayomi.tachidesk.config.server.systemTrayEnabled=false" `
    -jar "$SERVER_JAR_ABSOLUTE_PATH"
