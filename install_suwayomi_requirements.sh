#!/bin/bash

# Suwayomi Server and WebUI Prerequisites Installation Script

echo "Starting Suwayomi prerequisites installation..."

# Detect OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "Detected Windows (Git Bash). Please ensure you have Java Development Kit (JDK 21 or higher), Node.js, npm, and curl installed manually."
    echo "This script does not automate installations for Windows."
else
    # Linux/Ubuntu/NixOS (common for Codespaces)
    echo "Detected Linux/Unix. Installing prerequisites via apt..."

    # Update package lists
    sudo apt-get update || { echo "Failed to update apt. Exiting."; exit 1; }

    # Install OpenJDK 21 and curl
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

echo "Suwayomi prerequisites installation complete."