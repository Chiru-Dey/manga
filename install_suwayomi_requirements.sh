#!/bin/bash

# Installation script for Suwayomi development environment
# This script installs: fnm, Node.js 22.12.0, Yarn, Eclipse Temurin JDK 21, and xvfb

set -e  # Exit on any error

echo "🚀 Installing dependencies for Suwayomi development environment..."
echo "=================================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print status messages
print_status() {
    echo "✅ $1"
}

print_error() {
    echo "❌ $1"
}

print_info() {
    echo "ℹ️  $1"
}

# Update package list
print_info "Updating package list..."
sudo apt update

# Install basic dependencies
print_info "Installing basic dependencies..."
sudo apt install -y curl wget unzip gpg software-properties-common apt-transport-https

# 1. Install fnm (Fast Node Manager)
print_info "Installing fnm (Fast Node Manager)..."
if command_exists fnm; then
    print_status "fnm is already installed"
    fnm --version
else
    curl -fsSL https://fnm.vercel.app/install | bash
    
    # Source fnm for current session
    export PATH="$HOME/.fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
    
    # Add to shell profiles
    echo 'export PATH="$HOME/.fnm:$PATH"' >> ~/.bashrc
    echo 'eval "$(fnm env --use-on-cd)"' >> ~/.bashrc
    
    if [ -f ~/.zshrc ]; then
        echo 'export PATH="$HOME/.fnm:$PATH"' >> ~/.zshrc
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
    fi
    
    print_status "fnm installed successfully"
    fnm --version
fi

# 2. Install Node.js 22.12.0 using fnm
print_info "Installing Node.js 22.12.0 using fnm..."
# Source fnm environment
export PATH="$HOME/.fnm:$PATH"
eval "$(fnm env --use-on-cd)"

fnm install 22.12.0
fnm use 22.12.0
fnm default 22.12.0

print_status "Node.js installed successfully"
node --version

# 3. Install Yarn
print_info "Installing Yarn..."
if command_exists yarn; then
    print_status "Yarn is already installed"
    yarn --version
else
    npm install -g yarn
    print_status "Yarn installed successfully"
    yarn --version
fi

# 4. Remove existing OpenJDK installations
print_info "Removing existing OpenJDK installations..."
# Remove OpenJDK 11 if it exists
sudo apt remove --purge -y openjdk-11-jdk openjdk-11-jre openjdk-11-jre-headless 2>/dev/null || true
# Remove OpenJDK 21 if it exists (we'll install Temurin instead)
sudo apt remove --purge -y openjdk-21-jdk openjdk-21-jre openjdk-21-jre-headless 2>/dev/null || true

# Clean up
sudo apt autoremove -y

# 5. Install Eclipse Temurin JDK 21
print_info "Installing Eclipse Temurin JDK 21..."

# Add Adoptium repository
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg

echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list

# Update package list
sudo apt update

# Install Temurin JDK 21
sudo apt install -y temurin-21-jdk

# Set up alternatives for Temurin JDK 21 (higher priority than OpenJDK)
sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/temurin-21-jdk/bin/java 2121
sudo update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/temurin-21-jdk/bin/javac 2121

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/temurin-21-jdk
echo 'export JAVA_HOME=/usr/lib/jvm/temurin-21-jdk' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc

if [ -f ~/.zshrc ]; then
    echo 'export JAVA_HOME=/usr/lib/jvm/temurin-21-jdk' >> ~/.zshrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.zshrc
fi

print_status "Eclipse Temurin JDK 21 installed successfully"
java -version

# 6. Install xvfb (for headless display)
print_info "Installing xvfb..."
sudo apt install -y xvfb

print_status "xvfb installed successfully"
xvfb-run --help > /dev/null 2>&1 && print_status "xvfb-run is working"

# 7. Install additional development tools (optional but useful)
print_info "Installing additional development tools..."
sudo apt install -y git build-essential

print_status "Additional development tools installed"

# 8. Verify all installations
echo ""
echo "🔍 Verification of installations:"
echo "================================="

print_info "fnm version:"
fnm --version

print_info "Node.js version:"
node --version

print_info "npm version:"
npm --version

print_info "Yarn version:"
yarn --version

print_info "Java version:"
java -version

print_info "JAVA_HOME:"
echo $JAVA_HOME

print_info "xvfb-run test:"
xvfb-run --help > /dev/null 2>&1 && echo "xvfb-run is working" || echo "xvfb-run has issues"

# 9. Create a simple test script
print_info "Creating test script..."
cat > ~/test_environment.sh << 'EOF'
#!/bin/bash
echo "Testing development environment..."
echo "================================="

# Test fnm
echo "fnm: $(fnm --version)"

# Test Node.js
echo "Node.js: $(node --version)"

# Test npm
echo "npm: $(npm --version)"

# Test Yarn
echo "Yarn: $(yarn --version)"

# Test Java
echo "Java version:"
java -version

# Test JAVA_HOME
echo "JAVA_HOME: $JAVA_HOME"

# Test xvfb
echo "Testing xvfb..."
xvfb-run node -e "console.log('xvfb test successful')"

echo "✅ All tools are working correctly!"
EOF

chmod +x ~/test_environment.sh

print_status "Test script created at ~/test_environment.sh"

# 10. Final instructions
echo ""
echo "🎉 Installation completed successfully!"
echo "======================================"
echo ""
echo "To use the installed tools:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Test the installation by running: ~/test_environment.sh"
echo ""
echo "Installed versions:"
echo "- fnm: $(fnm --version)"
echo "- Node.js: $(node --version)"
echo "- Yarn: $(yarn --version)"
echo "- Java: Eclipse Temurin JDK 21"
echo "- xvfb: Available for headless display"
echo ""
echo "You can now run your Suwayomi build script!"
echo ""
echo "Note: If you're using a new terminal session, make sure to run:"
echo "source ~/.bashrc"
echo ""
echo "Or for immediate use in current session:"
echo "source ~/.bashrc"
echo "eval \"\$(fnm env --use-on-cd)\""