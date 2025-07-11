# Suwayomi-Server Windows PowerShell Script
# Compatible with Windows 10
# Assumes Java is available in PATH and server JAR is in the same directory

# Define application-specific variables
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$CUSTOM_DATA_ROOT = "$SCRIPT_DIR\suwayomi-data"
$CUSTOM_WEBUI_TARGET_DIR = "$CUSTOM_DATA_ROOT\webUI"
$SERVER_CONF_FILE = "$CUSTOM_DATA_ROOT\server.conf"

# --- Kill previous server process (if any) ---
Write-Host "Attempting to kill any running Suwayomi-Server processes..."
try {
    Get-Process | Where-Object { $_.ProcessName -eq "java" -and $_.CommandLine -like "*Suwayomi-Server*" } | Stop-Process -Force
    Write-Host "Killed existing Suwayomi-Server processes."
}
catch {
    Write-Host "No existing Suwayomi-Server processes found or unable to kill them."
}
Start-Sleep -Seconds 2

# Check if the Suwayomi JAR file exists in the script directory
$SERVER_JAR_PATH = Get-ChildItem -Path $SCRIPT_DIR -Filter "Suwayomi-Server-*.jar" | Select-Object -First 1
if (-not $SERVER_JAR_PATH) {
    Write-Host "Error: Suwayomi-Server JAR not found in script directory!"
    Write-Host "Please ensure the JAR file (Suwayomi-Server-*.jar) is in the same folder as this script."
    exit 1
}

# Get the absolute path of the JAR
$SERVER_JAR_ABSOLUTE_PATH = $SERVER_JAR_PATH.FullName
Write-Host "Suwayomi-Server JAR found: $SERVER_JAR_ABSOLUTE_PATH"

# --- Determine WebUI Access Link ---
$SERVER_IP = "localhost"
$SERVER_PORT = "8080"

if (Test-Path $SERVER_CONF_FILE) {
    # Extract IP and Port from server.conf
    $configContent = Get-Content $SERVER_CONF_FILE
    
    $ipLine = $configContent | Where-Object { $_ -match 'ip\s*=' }
    if ($ipLine -and $ipLine -match '"([^"]+)"') {
        $CONFIG_IP = $matches[1].Trim()
        if ($CONFIG_IP -eq "0.0.0.0") {
            $SERVER_IP = "localhost"
        }
        else {
            $SERVER_IP = $CONFIG_IP
        }
    }
    
    $portLine = $configContent | Where-Object { $_ -match 'port\s*=' }
    if ($portLine -and $portLine -match 'port\s*=\s*(\d+)') {
        $SERVER_PORT = $matches[1].Trim()
    }
}

# --- Create data directory if it doesn't exist ---
if (-not (Test-Path $CUSTOM_DATA_ROOT)) {
    New-Item -ItemType Directory -Path $CUSTOM_DATA_ROOT -Force | Out-Null
    Write-Host "Created data directory: $CUSTOM_DATA_ROOT"
}

# --- Run Suwayomi-Server with custom WebUI path ---
Write-Host "Starting Suwayomi-Server with local WebUI..."
Write-Host "Server Data Root: $CUSTOM_DATA_ROOT"
Write-Host "WebUI Flavor: CUSTOM (server will use local files)"
Write-Host "Access the WebUI at: http://${SERVER_IP}:${SERVER_PORT}"
Write-Host ""

# Create the java command arguments
$javaArgs = @(
    "-Dsuwayomi.tachidesk.config.server.rootDir=`"$CUSTOM_DATA_ROOT`"",
    "-Dsuwayomi.tachidesk.config.server.webUIFlavor=CUSTOM",
    "-Dsuwayomi.tachidesk.config.server.webUI.autoDownload=false",
    "-Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false",
    "-Dsuwayomi.tachidesk.config.server.systemTrayEnabled=false",
    "-jar",
    "`"$SERVER_JAR_ABSOLUTE_PATH`""
)

# Run the server in a new process (run and forget)
Write-Host "Starting Suwayomi-Server in background..."
Write-Host "You can close this PowerShell window - the server will continue running."
Write-Host "To stop the server later, look for 'java.exe' processes in Task Manager."

# Start the process and detach it
$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
$processStartInfo.FileName = "java"
$processStartInfo.Arguments = $javaArgs -join " "
$processStartInfo.UseShellExecute = $false
$processStartInfo.RedirectStandardOutput = $false
$processStartInfo.RedirectStandardError = $false
$processStartInfo.CreateNoWindow = $false

try {
    $process = [System.Diagnostics.Process]::Start($processStartInfo)
    Write-Host "Server started successfully with Process ID: $($process.Id)"
    Write-Host "WebUI should be available at: http://${SERVER_IP}:${SERVER_PORT}"
    
    # Wait a moment to ensure the process started
    Start-Sleep -Seconds 3
    
    if (-not $process.HasExited) {
        Write-Host "Server is running in the background. This script will now exit."
        Write-Host "The server will continue running even after closing this window."
    }
    else {
        Write-Host "Warning: Server process appears to have exited immediately. Check for errors."
    }
}
catch {
    Write-Host "Error starting server: $($_.Exception.Message)"
    Write-Host "Make sure Java is installed and available in your PATH."
    exit 1
}

# Optional: Open the WebUI in default browser
$openBrowser = Read-Host "Open WebUI in browser? (y/n)"
if ($openBrowser -eq 'y' -or $openBrowser -eq 'Y') {
    Start-Process "http://${SERVER_IP}:${SERVER_PORT}"
}

Write-Host "Script execution completed. Server should be running in background."