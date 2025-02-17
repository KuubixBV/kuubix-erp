#!/bin/bash

CUSTOM_DIR="../custom"
DEPLOY_SCRIPT="./deploy.sh"

# Detect the operating system
OS=$(uname -s)

echo "Detected OS: $OS"

case "$OS" in
    Linux*)
        # Check if running under WSL (Windows Subsystem for Linux)
        if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
            echo "Running under WSL. Using PowerShell to monitor changes..."
            powershell.exe -File watch-windows.ps1
            exit 0
        else
            WATCH_TOOL="inotifywait"
        fi
        ;;
    Darwin*)
        WATCH_TOOL="fswatch"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        echo "Detected Windows environment. Running PowerShell script..."
        powershell.exe -File watch-windows.ps1
        exit 0
        ;;
    *)
        echo "Unsupported OS. Exiting."
        exit 1
        ;;
esac

# Check if the required tool is installed
if ! command -v "$WATCH_TOOL" &> /dev/null; then
    echo "Error: $WATCH_TOOL is not installed. Please install it."
    exit 1
fi

echo "Watching for changes in $CUSTOM_DIR using $WATCH_TOOL..."

if [ "$WATCH_TOOL" = "inotifywait" ]; then
    inotifywait -m -r -e modify,create,delete,move --format '%w%f' "$CUSTOM_DIR" | while read change; do
        main_module=$(echo "$change" | awk -F'/' '{print $3}')
        if [ -n "$main_module" ]; then
            echo "Change detected in $main_module. Deploying..."
            bash "$DEPLOY_SCRIPT" --folder "$main_module"
        fi
    done
elif [ "$WATCH_TOOL" = "fswatch" ]; then
    fswatch -o "$CUSTOM_DIR" | while read change; do
        main_module=$(find "$CUSTOM_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1 | xargs -I {} basename {})
        if [ -n "$main_module" ]; then
            echo "Change detected in $main_module. Deploying..."
            bash "$DEPLOY_SCRIPT" --folder "$main_module"
        fi
    done
fi

