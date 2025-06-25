# Suwayomi Server and WebUI Startup Script Plan

This document outlines the plan for creating a cross-platform shell script (`start_suwayomi.sh`) to manage the Suwayomi server and launch its web UI, including the installation of necessary prerequisites for a GitHub Codespace environment.

## 1. Understanding the Components

*   **Suwayomi-Server:** A Kotlin JVM project. The `shadowJar` Gradle task in `Suwayomi-Server/server/build.gradle.kts` produces a fat JAR, expected to be named `Suwayomi-Server-&lt;version&gt;.jar` in `/workspaces/manga/Suwayomi-Server/server/build/`.
*   **Suwayomi-Launcher:** A Kotlin JVM project. Its `shadowJar` Gradle task in `Suwayomi-Launcher/build.gradle.kts` produces `Suwayomi-Launcher.jar` in `/workspaces/manga/Suwayomi-Launcher/build/`. This launcher is responsible for starting the Suwayomi server.
*   **Suwayomi-WebUI:** A JavaScript/TypeScript project. `npm install` and `npm run build` are used to build the web UI, which will reside in the `/workspaces/manga/Suwayomi-WebUI/build` directory.
*   **Server Startup & Readiness:** The `Suwayomi-Launcher` starts the server. The server listens on port `4567`. Its readiness can be reliably checked by polling the `http://127.0.0.1:4567/api/v1/settings/about/` endpoint for an HTTP 200 response.
*   **Stopping Previous Instances:** The script will prioritize stopping existing server instances by PID for accuracy.
*   **Operating Systems:** The script must support Windows (Git Bash) and Linux (NixOS, Ubuntu).

## 2. Proposed Plan

### 2.1. Install Prerequisites (for GitHub Codespace / Linux environments)

This section will be added to the script to ensure all necessary tools are available before attempting to build or run the applications.

*   **Java Development Kit (JDK 21):**
    *   Update package lists: `sudo apt-get update`
    *   Install OpenJDK 21: `sudo apt-get install -y openjdk-21-jdk`
    *   Set `JAVA_HOME` and add to `PATH` (usually handled by `apt` or can be explicitly set in the script).
*   **Node.js and npm:**
    *   Install Node.js (LTS version) and npm: `curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs`
*   **Curl:**
    *   Ensure `curl` is installed: `sudo apt-get install -y curl` (if not already present).
*   **Gradle:**
    *   The projects use `gradlew` (Gradle Wrapper), which will download the correct Gradle version, so a global Gradle installation is not strictly necessary, as long as Java is installed.

### 2.2. Build Suwayomi Components

Before running the server and web UI, ensure all necessary components are built.

*   **Suwayomi-Server:**
    *   Navigate to the `Suwayomi-Server` root directory: `cd /workspaces/manga/Suwayomi-Server`
    *   Execute the Gradle `shadowJar` task: `./gradlew shadowJar`
    *   Expected output path: `/workspaces/manga/Suwayomi-Server/server/build/Suwayomi-Server-*.jar` (using a wildcard for the version).

*   **Suwayomi-Launcher:**
    *   Navigate to the `Suwayomi-Launcher` root directory: `cd /workspaces/manga/Suwayomi-Launcher`
    *   Execute the Gradle `shadowJar` task: `./gradlew shadowJar`
    *   Expected output path: `/workspaces/manga/Suwayomi-Launcher/build/Suwayomi-Launcher.jar`.

*   **Suwayomi-WebUI:**
    *   Navigate to the `Suwayomi-WebUI` root directory: `cd /workspaces/manga/Suwayomi-WebUI`
    *   Install Node.js dependencies: `npm install`
    *   Build the web UI: `npm run build`
    *   Expected output path: `/workspaces/manga/Suwayomi-WebUI/build`.

### 2.3. Create Cross-Platform Script (`start_suwayomi.sh`)

The script will be a shell script, designed to be executable on both Windows (via Git Bash) and Linux environments.

### 2.4. Script Logic

The script will follow these steps:

#### 2.4.1. Define Paths and Variables

```bash
#!/bin/bash

# Define root directories
SUWAYOMI_SERVER_ROOT_DIR="/workspaces/manga/Suwayomi-Server"
SUWAYOMI_LAUNCHER_ROOT_DIR="/workspaces/manga/Suwayomi-Launcher"
SUWAYOMI_WEBUI_ROOT_DIR="/workspaces/manga/Suwayomi-WebUI"

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
```

#### 2.4.2. Install Prerequisites (within the script)

```bash
echo "Checking and installing prerequisites..."

# Detect OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "Detected Windows (Git Bash). Assuming necessary tools are available or will be installed manually."
    # For Windows, assume user has Java, Node.js, npm, curl, etc. installed or will install them.
    # Automated installation via Git Bash is more complex and outside the scope of a simple script.
else
    # Linux/Ubuntu/NixOS (common for Codespaces)
    echo "Detected Linux/Unix. Installing prerequisites via apt..."
    sudo apt-get update || { echo "Failed to update apt. Exiting."; exit 1; }
    sudo apt-get install -y openjdk-21-jdk curl || { echo "Failed to install JDK or curl. Exiting."; exit 1; }

    # Install Node.js and npm
    if ! command -v node &> /dev/null; then
        echo "Node.js not found. Installing Node.js and npm..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - || { echo "Failed to add NodeSource repo. Exiting."; exit 1; }
        sudo apt-get install -y nodejs || { echo "Failed to install Node.js. Exiting."; exit 1; }
    else
        echo "Node.js and npm are already installed."
    fi
fi

echo "Prerequisites check/installation complete."
```

#### 2.4.3. Stop Existing Server Instances

This section will handle stopping any previously running Suwayomi server instances.

```bash
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
```

#### 2.4.4. Determine Java Executable Path

The script will attempt to use a bundled JRE first, then fall back to the system's `java` command.

```bash
# Determine Java executable path
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
```

#### 2.4.5. Start Suwayomi Server

The script will start the Suwayomi Launcher, which in turn starts the server.

```bash
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
```

#### 2.4.6. Wait for Server to Load

The script will poll the server's readiness endpoint.

```bash
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
```

#### 2.4.7. Open WebUI in Default Browser

Once the server is ready, the web UI will be opened.

```bash
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
```

## 3. Mermaid Diagram

```mermaid
graph TD
    A[Start Script] --> P[Install Prerequisites];
    P --> B{Check if Suwayomi Components are Built};
    B -- No --> C[Build Suwayomi-Server JAR];
    C --> D[Build Suwayomi-Launcher JAR];
    D --> E[Install Suwayomi-WebUI Dependencies];
    E --> F[Build Suwayomi-WebUI];
    F --> G{Detect OS};
    B -- Yes --> G;
    G -- Windows --> H[Find & Kill Server by PID (Port 4567 or JAR name)];
    G -- Linux/Unix --> I[Find & Kill Server by PID (Port 4567 or JAR name)];
    H --> J[Determine Java Executable Path];
    I --> J;
    J --> K[Start Suwayomi Launcher in Background, Save PID];
    K --> L{Poll Server Readiness (http://127.0.0.1:4567/api/v1/settings/about/)};
    L -- Server Ready --> M[Open WebUI in Default Browser];
    L -- Timeout/Error --> N[Display Error and Exit];
    M --> O[Script Complete];
```

This revised plan now includes the necessary steps for installing prerequisites, making it suitable for environments like GitHub Codespaces where these tools might not be pre-installed.