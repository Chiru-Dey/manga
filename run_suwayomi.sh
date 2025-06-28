#!/bin/bash

# --- Configuration ---
SUWAYOMI_SERVER_DIR="Suwayomi-Server"
SUWAYOMI_WEBUI_DIR="Suwayomi-WebUI"
# This will be the new data root for the server. It will be created in the current directory.
CUSTOM_DATA_ROOT="$(pwd)/suwayomi-data"
# The server expects the WebUI to be in a 'webUI' subdirectory of its data root.
CUSTOM_WEBUI_TARGET_DIR="$CUSTOM_DATA_ROOT/webUI"
SERVER_CONF_FILE="$CUSTOM_DATA_ROOT/server.conf"

# --- Set JAVA_HOME for Suwayomi-Server build (using JDK 21 as per user feedback) ---
echo "Setting JAVA_HOME to JDK 21 for Suwayomi-Server build..."
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"
echo "JAVA_HOME set to: $JAVA_HOME"
if [ ! -d "$JAVA_HOME" ]; then
    echo "Error: JDK 21 not found at $JAVA_HOME. Please ensure it's installed or update the script with the correct path."
    exit 1
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
# Clean previous builds and then run the Gradle shadowJar task to build the executable JAR
rm -rf server/build/*.jar
rm -rf server/build/libs/*.jar
./gradlew shadowJar
if [ $? -ne 0 ]; then
    echo "Error: Suwayomi-Server build failed! Exiting."
    exit 1
fi
# Find the generated JAR file path
SERVER_JAR_PATH=$(find server/build -maxdepth 1 -name "Suwayomi-Server-*.jar" | head -n 1)
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

# Switch Node version
# Source NVM if available
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
  echo "NVM sourced."
  nvm use 22.12.0
  if [ $? -ne 0 ]; then
      echo "Error: Failed to switch Node.js version to 22.12.0 using NVM. Exiting."
      exit 1
  fi
else
  echo "Warning: NVM not found or nvm.sh script not accessible. Ensure NVM is installed and configured correctly."
  echo "Attempting to proceed without NVM, but Node.js version might be incorrect."
fi

# Install Node.js dependencies
yarn install
if [ $? -ne 0 ]; then
    echo "Error: Suwayomi-WebUI yarn install failed! Exiting."
    exit 1
fi

# Verify vite is installed
echo "Verifying vite installation..."
npx vite --version
if [ $? -ne 0 ]; then
    echo "Warning: vite not found or not working. This might cause issues with the WebUI build."
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