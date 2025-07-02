#!/bin/bash
# Define application-specific variables

SUWAYOMI_SERVER_DIR="Suwayomi-Server"
SUWAYOMI_WEBUI_DIR="Suwayomi-WebUI"
# This will be the new data root for the server. It will be created in the current directory.
CUSTOM_DATA_ROOT="$(pwd)/suwayomi-data"
# The server expects the WebUI to be in a 'webUI' subdirectory of its data root.
CUSTOM_WEBUI_TARGET_DIR="$CUSTOM_DATA_ROOT/webUI"
SERVER_CONF_FILE="$CUSTOM_DATA_ROOT/server.conf"
# Function to get Java version and set JAVA_HOME
# --- Dynamically set JAVA_HOME and check Java version (21 or higher) ---
find_java_home_and_check_version() {
    local required_version=21
    local java_cmd=""
    local java_version=""
    local java_major_version=0
    local java_home_path=""

    # Try to find Java using update-alternatives (common on Debian/Ubuntu)
    if command -v update-alternatives &> /dev/null; then
        java_cmd=$(update-alternatives --query java | grep "Value:" | awk '{print $2}')
        if [ -n "$java_cmd" ]; then
            java_home_path=$(dirname $(dirname "$java_cmd"))
        fi
    fi

    # Fallback if update-alternatives didn't find it or is not available
    if [ -z "$java_cmd" ]; then
        java_cmd=$(which java)
        if [ -n "$java_cmd" ]; then
            java_home_path=$(dirname $(dirname "$java_cmd"))
        fi
    fi

    if [ -z "$java_cmd" ]; then
        echo "Error: Java executable not found. Please ensure Java is installed and in your PATH."
        exit 1
    fi

    # Get Java version
    java_version=$("$java_cmd" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    if [ -z "$java_version" ]; then
        echo "Error: Could not determine Java version from '$java_cmd -version'."
        exit 1
    fi

    # Extract major version number
    java_major_version=$(echo "$java_version" | awk -F'.' '{print $1}')
    # Handle Java 9+ versioning (e.g., "9", "10", "11", "17", "21")
    if [[ "$java_major_version" =~ ^[0-9]+$ && "$java_major_version" -lt 9 ]]; then
        # For Java 1.x.x versions, the major version is the second part (e.g., 1.8.0 -> 8)
        java_major_version=$(echo "$java_version" | awk -F'.' '{print $2}')
    fi

    echo "Detected Java version: $java_version (Major: $java_major_version)"

    # Check if the major version is greater than or equal to the required version
    if (( java_major_version < required_version )); then
        echo "Error: Suwayomi-Server requires Java $required_version or higher. Detected version: $java_major_version."
        exit 1
    fi

    echo "Java version $java_major_version is compatible."
    export JAVA_HOME="$java_home_path"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "JAVA_HOME set to: $JAVA_HOME"
}

# Call the function to set JAVA_HOME and validate version
find_java_home_and_check_version

# --- Kill previous server process (if any) ---
echo "Attempting to kill any running Suwayomi-Server processes..."
# This command attempts to kill processes whose command line contains "Suwayomi-Server".
# It might not catch all instances or could be too broad if other Java apps use similar names.
pkill -f "Suwayomi-Server"
sleep 2 # Give it a moment to terminate

# Check if the Suwayomi JAR file exists
SERVER_JAR_PATH=$(find Suwayomi-Server/server/build -maxdepth 1 -name "Suwayomi-Server-*.jar" | head -n 1)
if [ -z "$SERVER_JAR_PATH" ]; then
    echo "Error: Suwayomi-Server JAR not found after build! Exiting."
    exit 1
fi
# Get the absolute path of the JAR
SERVER_JAR_ABSOLUTE_PATH="$(pwd)/$SERVER_JAR_PATH"
echo "Suwayomi-Server JAR built: $SERVER_JAR_ABSOLUTE_PATH"
# --- Determine WebUI Access Link ---
SERVER_IP="localhost"
SERVER_PORT="8080"

if [ -f "$SERVER_CONF_FILE" ]; then
    # Extract IP and Port from server.conf
    # Assuming format like: ip = "0.0.0.0" and port = 8080
    CONFIG_IP=$(grep "ip =" "$SERVER_CONF_FILE" | awk -F'"' '{print $2}' | tr -d '[:space:]')
    CONFIG_PORT=$(grep "port =" "$SERVER_CONF_FILE" | awk '{print $3}' | tr -d '[:space:]')

    if [ -n "$CONFIG_IP" ]; then
        # If IP is 0.0.0.0, use localhost for user-facing URL
        if [ "$CONFIG_IP" == "0.0.0.0" ]; then
            SERVER_IP="localhost"
        else
            SERVER_IP="$CONFIG_IP"
        fi
    fi
    if [ -n "$CONFIG_PORT" ]; then
        SERVER_PORT="$CONFIG_PORT"
    fi
fi

# --- Run Suwayomi-Server with custom WebUI path ---
echo "Starting Suwayomi-Server with local WebUI..."
echo "Server Data Root: $CUSTOM_DATA_ROOT"
echo "WebUI Flavor: CUSTOM (server will use local files)"
echo "Access the WebUI at: http://${SERVER_IP}:${SERVER_PORT}"
echo "" # Newline for readability

# Run the server, setting the data root and WebUI flavor via system properties
xvfb-run java -Djava.awt.headless=true \
             -Dcef.headless=true \
             -Dsuwayomi.tachidesk.config.server.rootDir="$CUSTOM_DATA_ROOT" \
             -Dsuwayomi.tachidesk.config.server.webUIFlavor=CUSTOM \
             -Dsuwayomi.tachidesk.config.server.webUI.autoDownload=false \
             -Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false \
             -Dsuwayomi.tachidesk.config.server.systemTrayEnabled=false \
             -jar "$SERVER_JAR_ABSOLUTE_PATH"