#!/bin/bash

# Function to get Java version and set JAVA_HOME
get_java_version() {
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

    export JAVA_HOME="$java_home_path"
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "JAVA_HOME set to: $JAVA_HOME"

    echo "$java_major_version" # Return the major version
}

# Function to check if Java version meets the requirement
check_java_version() {
    local required_version=$1
    local detected_major_version=$(get_java_version)

    if (( detected_major_version < required_version )); then
        echo "Error: Suwayomi-Server requires Java $required_version or higher. Detected version: $detected_major_version."
        exit 1
    fi

    echo "Java version $detected_major_version is compatible."
}

# Call the function to check Java version
check_java_version 21

# Execute the existing Suwayomi application JAR
echo "Starting Suwayomi application..."
"$JAVA_HOME/bin/java" -jar build/libs/suwayomi.jar