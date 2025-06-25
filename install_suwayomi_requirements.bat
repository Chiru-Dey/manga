@echo off
setlocal

echo --- Installing Suwayomi Prerequisites ---

:: --- Install Chocolatey (if not present) ---
echo.
echo Checking for Chocolatey (package manager)...
where choco >nul 2>&1
if %errorlevel% ne 0 (
    echo Chocolatey not found. Installing Chocolatey...
    echo.
    echo You might need to run this script as Administrator.
    echo Follow the instructions on screen to complete Chocolatey installation.
    powershell.exe -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    if %errorlevel% ne 0 (
        echo Error: Failed to install Chocolatey. Please install it manually from https://chocolatey.org/install
        goto :eof
    )
    echo Chocolatey installed. Please restart this script in a new Administrator command prompt.
    goto :eof
) else (
    echo Chocolatey is already installed.
)

:: --- Install JDK 11+ ---
echo.
echo Checking for Java Development Kit (JDK) 11 or higher...
choco install -y openjdk --version=11
if %errorlevel% ne 0 (
    echo Error: Failed to install OpenJDK 11. Please check Chocolatey logs or install manually.
) else (
    echo OpenJDK 11 installed successfully.
)

:: --- Install Node.js 20+ (LTS) ---
echo.
echo Checking for Node.js 20 (LTS) or higher...
choco install -y nodejs-lts
if %errorlevel% ne 0 (
    echo Error: Failed to install Node.js LTS. Please check Chocolatey logs or install manually.
) else (
    echo Node.js LTS installed successfully.
)

:: --- Install Yarn ---
echo.
echo Checking for Yarn...
where yarn >nul 2>&1
if %errorlevel% ne 0 (
    echo Yarn not found. Installing Yarn globally via npm...
    npm install -g yarn
    if %errorlevel% ne 0 (
        echo Error: Failed to install Yarn. Please install it manually: npm install -g yarn
    ) else (
        echo Yarn installed successfully.
    )
) else (
    echo Yarn is already installed.
)

echo.
echo --- Prerequisite installation complete. ---
echo Please verify that JDK 11+ and Node.js 20+ (with Yarn) are correctly installed.
echo You might need to restart your command prompt for changes to take effect.

endlocal