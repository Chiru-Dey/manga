# Suwayomi-Server Windows PowerShell Script
# Compatible with Windows 10

# Define application-specific variables
$SUWAYOMI_SERVER_DIR = "Suwayomi-Server"
# This will be the new data root for the server. It will be created in the current directory.
$CUSTOM_DATA_ROOT = "$(Get-Location)\suwayomi-data"
# The server expects the WebUI to be in a 'webUI' subdirectory of its data root.

# Function to get Java version and set JAVA_HOME
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

# Check if the Suwayomi JAR file exists
$SERVER_JAR_PATH = Get-ChildItem -Path "Suwayomi-Server\server\build" -Filter "Suwayomi-Server-*.jar" | Select-Object -First 1
if (-not $SERVER_JAR_PATH) {
    Write-Host "Error: Suwayomi-Server JAR not found after build! Exiting."
    Write-Host "Please ensure the JAR file exists in: Suwayomi-Server\server\build\"
    exit 1
}

# Get the absolute path of the JAR
$SERVER_JAR_ABSOLUTE_PATH = $SERVER_JAR_PATH.FullName
Write-Host "Suwayomi-Server JAR found: $SERVER_JAR_ABSOLUTE_PATH"

# Create the java command arguments

# Run the server in a new process (run and forget)

java -Dsuwayomi.tachidesk.config.server.rootDir="$CUSTOM_DATA_ROOT" \
    -Dsuwayomi.tachidesk.config.server.webUIFlavor=CUSTOM \
    -Dsuwayomi.tachidesk.config.server.webUI.autoDownload=false \
    -Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false \
    -Dsuwayomi.tachidesk.config.server.systemTrayEnabled=false \
    -jar "$SERVER_JAR_ABSOLUTE_PATH"