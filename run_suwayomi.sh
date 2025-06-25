#!/bin/bash

# --- Configuration ---
SUWAYOMI_SERVER_DIR="Suwayomi-Server"
SUWAYOMI_WEBUI_DIR="Suwayomi-WebUI"
# This will be the new data root for the server. It will be created in the current directory.
CUSTOM_DATA_ROOT="$(pwd)/suwayomi-data"
# The server expects the WebUI to be in a 'webUI' subdirectory of its data root.
CUSTOM_WEBUI_TARGET_DIR="$CUSTOM_DATA_ROOT/webUI"
SERVER_CONF_FILE="$CUSTOM_DATA_ROOT/server.conf"

# --- Set JAVA_HOME to JDK 11 if available ---
echo "Attempting to set JAVA_HOME to JDK 11..."
JAVA_HOME_CANDIDATE=""

# Try to find java executable in PATH and derive JAVA_HOME
JAVA_BIN=$(which java 2>/dev/null)
if [ -n "$JAVA_BIN" ]; then
    # Resolve symlinks to get the real path
    JAVA_REAL_PATH=$(readlink -f "$JAVA_BIN")
    # JAVA_HOME is typically two levels up from the 'java' executable (e.g., /path/to/jdk/bin/java)
    JAVA_HOME_CANDIDATE=$(dirname "$(dirname "$JAVA_REAL_PATH")")

    # Verify if it's a JDK 11 or higher
    if [ -f "$JAVA_HOME_CANDIDATE/bin/java" ]; then
        JAVA_VERSION=$("$JAVA_HOME_CANDIDATE/bin/java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
        # Check for versions like "11.0.x", "12.x", "1.11.x", etc.
        if [[ "$JAVA_VERSION" =~ ^1\.11\. ]] || [[ "$JAVA_VERSION" =~ ^11\. ]] || [[ "$JAVA_VERSION" =~ ^1[2-9]\. ]] || [[ "$JAVA_VERSION" =~ ^[2-9][0-9]\. ]]; then
            export JAVA_HOME="$JAVA_HOME_CANDIDATE"
            export PATH="$JAVA_HOME/bin:$PATH"
            echo "JAVA_HOME set to: $JAVA_HOME (Detected version: $JAVA_VERSION)"
        else
            echo "Warning: Found Java version $JAVA_VERSION, but it's not JDK 11 or higher. Attempting to use default Java."
        fi
    fi
fi

if [ -z "$JAVA_HOME" ]; then
    # Fallback to common paths if dynamic detection failed or found incompatible version
    if [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
        export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    elif [ -d "/usr/local/opt/openjdk@11/libexec/openjdk.jdk" ]; then
        export JAVA_HOME="/usr/local/opt/openjdk@11/libexec/openjdk.jdk"
    elif [ -d "/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home" ]; then
        export JAVA_HOME="/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home"
    fi

    if [ -n "$JAVA_HOME" ]; then
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "JAVA_HOME set to: $JAVA_HOME (from common paths fallback)"
    else
        echo "Warning: JDK 11 not found in common locations or via 'which java'. Attempting to use default Java. Build might fail if default is incompatible."
        echo "Please ensure JDK 11 is installed and accessible, or set JAVA_HOME manually before running this script."
    fi
fi


# --- Kill previous server process (if any) ---
echo "Attempting to kill any running Suwayomi-Server processes..."
# This command attempts to kill processes whose command line contains "Suwayomi-Server".
# It might not catch all instances or could be too broad if other Java apps use similar names.
pkill -f "Suwayomi-Server"
sleep 2 # Give it a moment to terminate

# --- Build Suwayomi-Server JAR ---
echo "Building Suwayomi-Server JAR..."
# Navigate to the server directory
cd "$SUWAYOMI_SERVER_DIR" || { echo "Error: Suwayomi-Server directory not found! Exiting."; exit 1; }
# Run the Gradle shadowJar task to build the executable JAR
./gradlew shadowJar
if [ $? -ne 0 ]; then
    echo "Error: Suwayomi-Server build failed! Exiting."
    exit 1
fi
# Find the generated JAR file path
SERVER_JAR_PATH=$(find server/build/libs -name "Suwayomi-Server-*.jar" | head -n 1)
if [ -z "$SERVER_JAR_PATH" ]; then
    echo "Error: Suwayomi-Server JAR not found after build! Exiting."
    exit 1
fi
# Get the absolute path of the JAR
SERVER_JAR_ABSOLUTE_PATH="$(pwd)/$SERVER_JAR_PATH"
echo "Suwayomi-Server JAR built: $SERVER_JAR_ABSOLUTE_PATH"
# Go back to the original directory
cd - > /dev/null

# --- Build Suwayomi-WebUI static files ---
echo "Building Suwayomi-WebUI static files..."
# Navigate to the WebUI directory
cd "$SUWAYOMI_WEBUI_DIR" || { echo "Error: Suwayomi-WebUI directory not found! Exiting."; exit 1; }
# Install Node.js dependencies
yarn install
if [ $? -ne 0 ]; then
    echo "Error: Suwayomi-WebUI yarn install failed! Exiting."
    exit 1
fi
# Build the WebUI for production
yarn build
if [ $? -ne 0 ]; then
    echo "Error: Suwayomi-WebUI build failed! Exiting."
    exit 1
fi
# Get the absolute path of the built WebUI directory
WEBUI_BUILD_DIR="$(pwd)/build"
echo "Suwayomi-WebUI built: $WEBUI_BUILD_DIR"
# Go back to the original directory
cd - > /dev/null

# --- Prepare custom data directory and copy WebUI ---
echo "Preparing custom data directory: $CUSTOM_DATA_ROOT"
# Clean up previous custom data directory if it exists
rm -rf "$CUSTOM_DATA_ROOT"
# Create the target directory structure
mkdir -p "$CUSTOM_WEBUI_TARGET_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create custom WebUI target directory! Exiting."
    exit 1
fi
# Copy the contents of the built WebUI into the target directory
cp -r "$WEBUI_BUILD_DIR"/* "$CUSTOM_WEBUI_TARGET_DIR"/
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy WebUI files to custom data directory! Exiting."
    exit 1
fi
echo "WebUI files copied to $CUSTOM_WEBUI_TARGET_DIR"

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
java -Dsuwayomi.tachidesk.config.server.rootDir="$CUSTOM_DATA_ROOT" \
     -Dsuwayomi.tachidesk.config.server.webUIFlavor=CUSTOM \
     -jar "$SERVER_JAR_ABSOLUTE_PATH"