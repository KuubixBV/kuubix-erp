#!/bin/bash

# File to store the current version
CURRENT_VERSION_FILE="./dolibarr/installed_version.txt"
DEFAULT_VERSION="19.0.2"
HTDOCS_URL="https://github.com/Dolibarr/dolibarr/archive/refs/tags"

# Function to download and extract the specified version
download_and_extract() {
    local version=$1
    local temp_dir=$(mktemp -d)

    echo "Downloading Dolibarr version $version on github $HTDOCS_URL/$version.zip - this will take a while ..."
    wget -q -O "$temp_dir/dolibarr-$version.zip" "$HTDOCS_URL/$version.zip"
    if [ $? -ne 0 ]; then
        echo "Failed to download version $version. Please check the version number and try again."
        rm -rf "$temp_dir"
        exit 1
    fi

    echo "Extracting files..."
    unzip -q "$temp_dir/dolibarr-$version.zip" -d "$temp_dir"
    if [ $? -ne 0 ]; then
        echo "Failed to extract files. Please check the downloaded archive and try again."
        rm -rf "$temp_dir"
        exit 1
    fi

    if [ ! -d "dolibarr" ]; then
        mkdir -p dolibarr
    fi

    echo "Moving htdocs contents to dolibarr directory..."
    mv "$temp_dir/dolibarr-$version/htdocs/"* dolibarr/

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
            rm -rf "$temp_dir"
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
