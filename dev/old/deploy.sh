#!/bin/bash

CUSTOM_DIR="../custom"
DOLIBARR_CUSTOM_DIR="../dolibarr/custom"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--folder) selected_folder="$CUSTOM_DIR/$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Get the list of folders inside the custom directory
folders=("$CUSTOM_DIR"/*/)

# Remove trailing slashes
folders=("${folders[@]%/}")

# Check if there are no folders
if [ ${#folders[@]} -eq 0 ]; then
    echo "Please use the Dolibarr module builder creator to create a new module."
    echo "Afterwards copy the created module from /dolibarr/custom/MY_MODULE to /custom/MY_MODULE."
    exit 1
fi

# If no folder was passed as a parameter, prompt the user
if [ -z "$selected_folder" ]; then
    # Auto-select if only one folder exists
    if [ ${#folders[@]} -eq 1 ]; then
        selected_folder=${folders[0]}
    else
        # Display available folders
        echo "Available modules in custom directory:"
        for i in "${!folders[@]}"; do
            echo "$((i+1)). $(basename "${folders[$i]}")"
        done

        # Ask the user to select a folder
        while true; do
            read -p "Enter the number of the folder to copy: " selection
            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#folders[@]} ]; then
                break
            else
                echo "Invalid selection. Please enter a valid number."
            fi
        done

        selected_folder=${folders[$((selection-1))]}
    fi
fi

# Extract the folder name
folder_name=$(basename "$selected_folder")

# Ensure the folder exists
if [ ! -d "$selected_folder" ]; then
    echo "Error: Folder '$folder_name' does not exist in $CUSTOM_DIR."
    exit 1
fi

echo "Copying $folder_name to Dolibarr custom directory..."

# Create destination directory if it doesn't exist
mkdir -p "$DOLIBARR_CUSTOM_DIR"

# Copy the selected folder
cp -r "$selected_folder" "$DOLIBARR_CUSTOM_DIR/"

echo "Module $folder_name successfully copied."
exit 0
