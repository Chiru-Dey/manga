#!/bin/bash

# Exit on any error
set -e

# Define variables
CUSTOM_DATA_ROOT="$(pwd)/suwayomi-data"
SERVER_JAR_PATH=$(find Suwayomi-Server/server/build -maxdepth 1 -name "Suwayomi-Server-*.jar" | head -n 1)
SERVER_JAR_ABSOLUTE_PATH="$(pwd)/$SERVER_JAR_PATH"
RUN_SCRIPT_SH="$(pwd)/run_suwayomi_existing.sh"
RUN_SCRIPT_PS1="$(pwd)/run_suwayomi_existing.ps1"

# Generate timestamp for unique release name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RELEASE_NAME="suwayomi-release-$TIMESTAMP"
ZIP_FILE="$RELEASE_NAME.zip"

echo "Starting Suwayomi release process..."
echo "Release name: $RELEASE_NAME"

# Check if required files/folders exist
echo "Checking for required files and folders..."

if [ ! -d "$CUSTOM_DATA_ROOT" ]; then
    echo "Error: Data folder not found at $CUSTOM_DATA_ROOT"
    exit 1
fi

if [ -z "$SERVER_JAR_PATH" ] || [ ! -f "$SERVER_JAR_ABSOLUTE_PATH" ]; then
    echo "Error: Server JAR file not found in Suwayomi-Server/server/build/"
    exit 1
fi

if [ ! -f "$RUN_SCRIPT_SH" ]; then
    echo "Error: Shell script not found at $RUN_SCRIPT_SH"
    exit 1
fi

if [ ! -f "$RUN_SCRIPT_PS1" ]; then
    echo "Error: PowerShell script not found at $RUN_SCRIPT_PS1"
    exit 1
fi

echo "All required files and folders found."

# Create temporary directory for organizing files
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Copy files to temp directory
echo "Copying files to temporary directory..."
cp -r "$CUSTOM_DATA_ROOT" "$TEMP_DIR/"
cp "$SERVER_JAR_ABSOLUTE_PATH" "$TEMP_DIR/"
cp "$RUN_SCRIPT_SH" "$TEMP_DIR/"
cp "$RUN_SCRIPT_PS1" "$TEMP_DIR/"

# Create zip file
echo "Creating zip file: $ZIP_FILE"
cd "$TEMP_DIR"
zip -r "../$ZIP_FILE" .
cd - > /dev/null

# Move zip file to current directory
mv "$TEMP_DIR/../$ZIP_FILE" "./$ZIP_FILE"

# Clean up temporary directory
rm -rf "$TEMP_DIR"

echo "Zip file created successfully: $ZIP_FILE"
echo "Zip file size: $(du -h "$ZIP_FILE" | cut -f1)"

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed or not in PATH"
    echo "Please install GitHub CLI to create releases automatically"
    echo "Zip file is ready at: $ZIP_FILE"
    exit 1
fi

# Check if user is authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI"
    echo "Please run 'gh auth login' to authenticate"
    echo "Zip file is ready at: $ZIP_FILE"
    exit 1
fi

# Create GitHub release
echo "Creating GitHub release..."
RELEASE_TAG="v$TIMESTAMP"
RELEASE_TITLE="Suwayomi Release $TIMESTAMP"
RELEASE_NOTES="Automated release created on $(date)

This release includes:
- Suwayomi data folder
- Server JAR file
- Run scripts for both Unix/Linux and Windows"

gh release create "$RELEASE_TAG" "$ZIP_FILE" \
    --title "$RELEASE_TITLE" \
    --notes "$RELEASE_NOTES" \
    --latest

echo "GitHub release created successfully!"
echo "Release tag: $RELEASE_TAG"
echo "Release title: $RELEASE_TITLE"
echo "Asset: $ZIP_FILE"

# Clean up zip file if release was successful
rm "$ZIP_FILE"
echo "Local zip file deleted."

echo "Release process completed!"