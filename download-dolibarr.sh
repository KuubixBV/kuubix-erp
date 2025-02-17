#!/bin/bash

# File to store the current version
CURRENT_VERSION_FILE="./dolibarr/installed_version.txt"
DEFAULT_VERSION="19.0.2"
REPO_URL="https://github.com/Dolibarr/dolibarr.git"

# Function to clone and extract only the htdocs directory
download_and_extract() {
    local version=$1
    local temp_dir=$(mktemp -d)

    echo "Cloning Dolibarr version $version from GitHub repository - this will take a while ..."
    git clone --branch "$version" --depth 1 --filter=blob:none --sparse "$REPO_URL" "$temp_dir"
    if [ $? -ne 0 ]; then
        echo "Failed to clone version $version. Please check the version number and try again."
        rm -rf "$temp_dir"
        exit 1
    fi

    cd "$temp_dir" || exit
    git sparse-checkout init --cone
    git sparse-checkout set htdocs
    git checkout "$version"
    cd - > /dev/null || exit

    if [ ! -d "dolibarr" ]; then
        mkdir -p dolibarr
    fi

    echo "Moving htdocs contents to dolibarr directory..."
    mv "$temp_dir/htdocs/"* dolibarr/

    echo "Cleaning up..."
    rm -rf "$temp_dir"

    sudo chown -R kuadmin:www-data ./dolibarr
    echo "Version $version installed successfully."

    # Update the current version file
    echo "$version" > $CURRENT_VERSION_FILE
}

# Check if a dolibarr version is installed
if [ -d "dolibarr" ]; then
    if [ "$(ls -A dolibarr)" ]; then
        echo "Warning: The dolibarr directory is not empty."
        read -p "Type 'I understand' to clear the directory and proceed: " confirmation
        if [ "$confirmation" != "I understand" ]; then
            echo "Operation cancelled."
            exit 1
        fi
        rm -rf dolibarr/*
    fi
fi

# Ask user for the version to download
read -p "Enter the version to download (default is $DEFAULT_VERSION): " version
version=${version:-$DEFAULT_VERSION}

# Download and extract the specified version
download_and_extract $version

