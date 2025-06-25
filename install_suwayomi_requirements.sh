#!/bin/bash

echo "--- Installing Suwayomi Prerequisites ---"

# --- Install JDK 21+ ---
echo "Checking for Java Development Kit (JDK) 21 or higher..."
if type -p java > /dev/null; then
    _java=java
elif [ -n "$JAVA_HOME" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    _java="$JAVA_HOME/bin/java"
fi

if [ -n "$_java" ]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    if [[ "$version" < "21" ]]; then
        echo "Found Java version $version, but 21 or higher is required."
        JAVA_INSTALLED=false
    else
        echo "JDK $version is already installed."
        JAVA_INSTALLED=true
    fi
else
    echo "JDK is not installed."
    JAVA_INSTALLED=false
fi

if [ "$JAVA_INSTALLED" = false ]; then
    echo "Attempting to install OpenJDK 21..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux (Debian/Ubuntu)
        if command -v apt &> /dev/null; then
            echo "Detected Debian/Ubuntu. Using apt."
            sudo apt update && sudo apt install -y openjdk-21-jdk
        # Linux (Fedora/CentOS/RHEL)
        elif command -v yum &> /dev/null; then
            echo "Detected Fedora/CentOS/RHEL. Using yum."
            sudo yum install -y java-21-openjdk-devel
        else
            echo "Unsupported Linux distribution. Please install OpenJDK 21 manually."
            echo "Refer to: https://openjdk.org/install/"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            echo "Detected macOS. Using Homebrew."
            brew install openjdk@21
            # Link OpenJDK to default JavaHome (optional, but good practice)
            sudo ln -sfn /usr/local/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk
            echo "Remember to add 'export PATH=\"/usr/local/opt/openjdk@21/bin:$PATH\"' to your shell profile (e.g., ~/.zshrc or ~/.bashrc)"
        else
            echo "Homebrew not found. Please install Homebrew (https://brew.sh/) and then run this script again, or install OpenJDK 21 manually."
            echo "Refer to: https://openjdk.org/install/"
        fi
    else
        echo "Unsupported operating system. Please install OpenJDK 21 manually."
        echo "Refer to: https://openjdk.org/install/"
    fi
fi

# --- Install Node.js 20+ and Yarn ---
echo ""
echo "Checking for Node.js 20 or higher..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    if [[ "$(echo "$NODE_VERSION" | cut -d'v' -f2 | cut -d'.' -f1)" -lt "20" ]]; then
        echo "Found Node.js version $NODE_VERSION, but 20 or higher is recommended."
        NODE_INSTALLED=false
    else
        echo "Node.js $NODE_VERSION is already installed."
        NODE_INSTALLED=true
    fi
else
    echo "Node.js is not installed."
    NODE_INSTALLED=false
fi

if [ "$NODE_INSTALLED" = false ]; then
    echo "Attempting to install Node.js 20..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "Detected Linux. Using NodeSource for Node.js installation."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "Detected macOS. Using Homebrew for Node.js installation."
        if command -v brew &> /dev/null; then
            brew install node
        else
            echo "Homebrew not found. Please install Homebrew (https://brew.sh/) and then run this script again, or install Node.js manually."
            echo "Refer to: https://nodejs.org/en/download/"
        fi
    else
        echo "Unsupported operating system. Please install Node.js 20+ manually."
        echo "Refer to: https://nodejs.org/en/download/"
    fi
fi

echo ""
echo "Checking for Yarn..."
if command -v yarn &> /dev/null; then
    echo "Yarn is already installed."
else
    echo "Yarn not found. Installing Yarn globally via npm..."
    npm install -g yarn
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Yarn. Please install it manually: npm install -g yarn"
    else
        echo "Yarn installed successfully."
    fi
fi

echo ""
echo "--- Prerequisite installation complete. ---"
echo "Please verify that JDK 21+ and Node.js 20+ (with Yarn) are correctly installed."
echo "You might need to restart your terminal or source your shell profile for changes to take effect."