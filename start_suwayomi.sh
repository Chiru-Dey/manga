#!/bin/bash

# Suwayomi Server and WebUI Startup Script

# Define root directories
SUWAYOMI_SERVER_ROOT_DIR="/workspaces/manga/Suwayomi-Server"
SUWAYOMI_LAUNCHER_ROOT_DIR="/workspaces/manga/Suwayomi-Launcher"
SUWAYOMI_WEBUI_ROOT_DIR="/workspaces/manga/Suwayomi-WebUI"

# Set JAVA_HOME for Gradle to use JDK 21
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Stopping any lingering Gradle daemons to ensure correct JDK is used..."
# Stop any existing Gradle daemons to ensure a fresh start with JDK 21
(cd "$SUWAYOMI_SERVER_ROOT_DIR" && ./gradlew --stop) >/dev/null 2>&1
(cd "$SUWAYOMI_LAUNCHER_ROOT_DIR" && ./gradlew --stop) >/dev/null 2>&1

# Define component paths (assuming they are built)
# Use a wildcard for the server JAR version
SERVER_JAR_GLOB="$SUWAYOMI_SERVER_ROOT_DIR/server/build/Suwayomi-Server-*.jar"
LAUNCHER_JAR_PATH="$SUWAYOMI_LAUNCHER_ROOT_DIR/build/Suwayomi-Launcher.jar"

# Server configuration
SERVER_PORT=4567
WEBUI_URL="http://127.0.0.1:$SERVER_PORT"
PID_FILE="$SUWAYOMI_LAUNCHER_ROOT_DIR/server.pid" # File to store server PID
SERVER_READINESS_ENDPOINT="$WEBUI_URL/api/v1/settings/about/"
SERVER_STARTUP_TIMEOUT=60 # seconds

echo "Starting Suwayomi Server and WebUI..."

# --- 1. Build Suwayomi Components (if not already built) ---
echo "Checking if Suwayomi components are built..."

# Build Suwayomi-Server
if [ ! -f "$SERVER_JAR_GLOB" ]; then
    echo "Suwayomi-Server JAR not found. Building now..."
    (cd "$SUWAYOMI_SERVER_ROOT_DIR" && ./gradlew shadowJar --info) || { echo "Error: Failed to build Suwayomi-Server. Exiting."; exit 1; }
    echo "Suwayomi-Server built successfully."
fi

# Build Suwayomi-Launcher
if [ ! -f "$LAUNCHER_JAR_PATH" ]; then
    echo "Suwayomi-Launcher JAR not found. Building now..."
    (cd "$SUWAYOMI_LAUNCHER_ROOT_DIR" && ./gradlew shadowJar --info) || { echo "Error: Failed to build Suwayomi-Launcher. Exiting."; exit 1; }
    echo "Suwayomi-Launcher built successfully."
fi

# Build Suwayomi-WebUI
if [ ! -d "$SUWAYOMI_WEBUI_ROOT_DIR/build" ]; then
    echo "Suwayomi-WebUI build directory not found. Building now..."
    (cd "$SUWAYOMI_WEBUI_ROOT_DIR" && npm install --legacy-peer-deps && npm run build) || { echo "Error: Failed to build Suwayomi-WebUI. Exiting."; exit 1; }
    echo "Suwayomi-WebUI built successfully."
fi

# --- 2. Stop Existing Server Instances ---
echo "Stopping any existing Suwayomi server instances..."

# Function to kill a process by PID
kill_process_by_pid() {
    local pid=$1
    if [ -n "$pid" ]; then
        echo "Attempting to kill process with PID: $pid"
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            # Windows (Git Bash)
            taskkill /PID "$pid" /F >/dev/null 2>&1
        else
            # Linux/Ubuntu/NixOS
            kill "$pid" >/dev/null 2>&1
        fi
        # Wait for the process to terminate
        for i in {1..10}; do
            if ! kill -0 "$pid" 2>/dev/null; then
                echo "Process $pid terminated."
                return 0
            fi
            sleep 1
        done
        echo "Warning: Process $pid might not have terminated gracefully."
        return 1
    fi
    return 0
}

# Try to kill using PID file first
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill_process_by_pid "$PID"; then
        rm -f "$PID_FILE"
    fi
fi

# Fallback: Find and kill processes by port or name
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows (Git Bash)
    echo "Searching for processes listening on port $SERVER_PORT (Windows)..."
    netstat -ano | findstr ":$SERVER_PORT" | awk '{print $5}' | while read -r PID; do
        if [ -n "$PID" ]; then
            echo "Found process listening on port $SERVER_PORT with PID: $PID"
            kill_process_by_pid "$PID"
        fi
    done

    echo "Searching for Java processes running Suwayomi JARs (Windows)..."
    wmic process where "commandline like '%%Suwayomi-Server.jar%%' OR commandline like '%%Suwayomi-Launcher.jar%%'" get processid | awk 'NR>1 {print $1}' | while read -r PID; do
        if [ -n "$PID" ]; then
            echo "Found Java process with PID: $PID"
            kill_process_by_pid "$PID"
        fi
    done
else
    # Linux/Ubuntu/NixOS
    echo "Searching for processes listening on port $SERVER_PORT (Linux/Unix)..."
    lsof -t -i :"$SERVER_PORT" | while read -r PID; do
        if [ -n "$PID" ]; then
            echo "Found process listening on port $SERVER_PORT with PID: $PID"
            kill_process_by_pid "$PID"
        fi
    done

    echo "Searching for Java processes running Suwayomi JARs (Linux/Unix)..."
    pgrep -f "java.*Suwayomi-Server.jar|java.*Suwayomi-Launcher.jar" | while read -r PID; do
        if [ -n "$PID" ]; then
            echo "Found Java process with PID: $PID"
            kill_process_by_pid "$PID"
        fi
    done
fi

echo "Previous server instances stopped (if any)."

# --- 3. Determine Java Executable Path ---
JAVA_CMD=""
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows (Git Bash)
    if [ -f "$SUWAYOMI_LAUNCHER_ROOT_DIR/jre/bin/javaw.exe" ]; then
        JAVA_CMD="$SUWAYOMI_LAUNCHER_ROOT_DIR/jre/bin/javaw.exe"
    elif [ -f "$SUWAYOMI_LAUNCHER_ROOT_DIR/jre/bin/java.exe" ]; then
        JAVA_CMD="$SUWAYOMI_LAUNCHER_ROOT_DIR/jre/bin/java.exe"
    else
        JAVA_CMD="java"
    fi
else
    # Linux/Ubuntu/NixOS
    if [ -f "$SUWAYOMI_LAUNCHER_ROOT_DIR/jre/bin/java" ]; then
        JAVA_CMD="$SUWAYOMI_LAUNCHER_ROOT_DIR/jre/bin/java"
    else
        JAVA_CMD="java"
    fi
fi

if [ -z "$JAVA_CMD" ]; then
    echo "Error: Could not determine Java executable path."
    exit 1
fi
echo "Using Java executable: $JAVA_CMD"

# --- 4. Start Suwayomi Server ---
echo "Starting Suwayomi server via launcher..."

# Start the launcher in the background
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows (Git Bash)
    # Using start /B to run in background without new window, output redirected to NUL
    start /B "" "$JAVA_CMD" -jar "$LAUNCHER_JAR_PATH" --launch >/dev/null 2>&1
    echo "Suwayomi server started in background (Windows)."
    # Note: Getting PID for background processes started with 'start' is complex in Git Bash.
    # Relying on port check for readiness.
else
    # Linux/Ubuntu/NixOS
    nohup "$JAVA_CMD" -jar "$LAUNCHER_JAR_PATH" --launch >/dev/null 2>&1 &
    echo $! > "$PID_FILE" # Save PID to file
    echo "Suwayomi server started in background (Linux/Unix). PID saved to $PID_FILE"
fi

# --- 5. Wait for Server to Load ---
echo "Waiting for Suwayomi server to fully load (timeout: ${SERVER_STARTUP_TIMEOUT}s)..."
START_TIME=$(date +%s)
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))

    if [ "$ELAPSED_TIME" -ge "$SERVER_STARTUP_TIMEOUT" ]; then
        echo "Error: Suwayomi server did not start within ${SERVER_STARTUP_TIMEOUT} seconds. Please check server logs for issues."
        exit 1
    fi

    # Check server readiness endpoint
    # Use -k for curl to ignore SSL certificate issues if any
    HTTP_CODE=$(curl -s -k -o /dev/null -w "%{http_code}" "$SERVER_READINESS_ENDPOINT")

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "Suwayomi server is fully loaded."
        break
    else
        echo "Server not ready yet (HTTP $HTTP_CODE). Retrying in 5 seconds..."
        sleep 5
    fi
done

# --- 6. Open WebUI in Default Browser ---
echo "Opening Suwayomi WebUI in default browser: $WEBUI_URL"

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows (Git Bash)
    start "$WEBUI_URL"
elif command -v xdg-open >/dev/null; then
    xdg-open "$WEBUI_URL"
elif command -v sensible-browser >/dev/null; then
    sensible-browser "$WEBUI_URL"
elif command -v gnome-open >/dev/null; then
    gnome-open "$WEBUI_URL"
elif command -v kde-open >/dev/null; then
    kde-open "$WEBUI_URL"
else
    echo "Warning: Could not find a suitable command to open the browser. Please open $WEBUI_URL manually."
fi

echo "Script finished."