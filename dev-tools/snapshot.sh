#!/bin/bash

# Load environment variables from .env file
if [ ! -f ../.env ]; then
    echo ".env file not found!"
    exit 1
fi

export $(grep -v '^#' ../.env | xargs)

# Directory to store snapshots
SNAPSHOT_DIR="../snapshots"

# Ensure the snapshot directory exists
mkdir -p $SNAPSHOT_DIR

# Function to install mysql-client if not present
install_mysql_client() {
    CONTAINER_ID=$(sudo docker ps -qf "name=mariadb")
    if [ -z "$CONTAINER_ID" ]; then
        echo "MariaDB container not found!"
        exit 1
    fi

    sudo docker exec -it $CONTAINER_ID bash -c "command -v mysql > /dev/null 2>&1 || (apt-get update && apt-get install -y mysql-client)"
    sudo docker exec -it $CONTAINER_ID bash -c "command -v mysqldump > /dev/null 2>&1 || (apt-get update && apt-get install -y mysql-client)"
}

# Function to sanitize filename
sanitize_filename() {
    echo "$1" | sed 's/[^a-zA-Z0-9_]/_/g'
}

# Function to save the database
save_db() {
    install_mysql_client

    read -p "Enter a name for the snapshot: " SNAPSHOT_NAME
    SNAPSHOT_NAME=$(sanitize_filename "$SNAPSHOT_NAME")

    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    FILENAME="$SNAPSHOT_DIR/${SNAPSHOT_NAME}_$TIMESTAMP.sql"

    echo "Saving database to $FILENAME..."
    sudo docker exec -i $(sudo docker ps -qf "name=mariadb") mysqldump --column-statistics=0 -u root -p$DB_PASSWORD dolibarr > $FILENAME

    if [ $? -eq 0 ]; then
        echo "Database saved successfully."
    else
        rm $FILENAME
        echo "Failed to save database."
        exit 1
    fi
}

# Function to format date
format_date() {
    local input_date=$1
    if [[ "$(uname)" == "Darwin" ]]; then
        date -j -f "%Y%m%d %H%M%S" "$input_date" "+%d/%m/%Y %H:%M"
    else
        date -d "$input_date" "+%d/%m/%Y %H:%M"
    fi
}

# Function to load the database
load_db() {
    install_mysql_client

    if [ -z "$1" ]; then
        SNAPSHOT_FILES=($SNAPSHOT_DIR/*.sql)
        if [ "${SNAPSHOT_FILES[0]}" == "$SNAPSHOT_DIR/*.sql" ]; then
            echo "No snapshot files found in $SNAPSHOT_DIR."
            exit 1
        fi

        echo "Available snapshots:"
        for i in "${!SNAPSHOT_FILES[@]}"; do
            SNAPSHOT_FILE=${SNAPSHOT_FILES[$i]}
            FILENAME=$(basename -- "$SNAPSHOT_FILE")
            TIMESTAMP=$(echo $FILENAME | grep -oE '[0-9]{8}_[0-9]{6}')
            DATE=$(format_date "${TIMESTAMP:0:8} ${TIMESTAMP:9:6}")
            NAME=$(echo $FILENAME | sed "s/_$TIMESTAMP.sql//")
            echo "$((i+1)). $NAME  $DATE"
        done

        read -p "Enter the number of the snapshot to load: " SNAPSHOT_NUMBER
        if ! [[ "$SNAPSHOT_NUMBER" =~ ^[0-9]+$ ]] || [ "$SNAPSHOT_NUMBER" -lt 1 ] || [ "$SNAPSHOT_NUMBER" -gt "${#SNAPSHOT_FILES[@]}" ]; then
            echo "Invalid selection."
            exit 1
        fi

        SNAPSHOT_FILE=${SNAPSHOT_FILES[$((SNAPSHOT_NUMBER-1))]}
    else
        SNAPSHOT_FILE=$1
    fi

    if [ ! -f $SNAPSHOT_FILE ]; then
        echo "Snapshot file $SNAPSHOT_FILE not found!"
        exit 1
    fi

    read -p "Do you want to save the current database state before loading the new snapshot? [Y/n]: " save_before
    save_before=${save_before:-Y}
    if [[ "$save_before" =~ ^[Yy]$ ]]; then
        save_db
    fi

    echo "Dropping and recreating the dolibarr database..."
    sudo docker exec -i $(sudo docker ps -qf "name=mariadb") mysql -u root -p$DB_PASSWORD -e "DROP DATABASE IF EXISTS dolibarr; CREATE DATABASE dolibarr;"

    if [ $? -ne 0 ]; then
        echo "Failed to drop and recreate database."
        exit 1
    fi

    echo "Importing snapshot..."
    cat $SNAPSHOT_FILE | sudo docker exec -i $(sudo docker ps -qf "name=mariadb") mysql -u root -p$DB_PASSWORD dolibarr

    if [ $? -eq 0 ]; then
        echo "Database loaded successfully."
    else
        echo "Failed to load database."
        exit 1
    fi
}

# Main script logic
if [ "$1" == "save" ]; then
    save_db
elif [ "$1" == "load" ]; then
    load_db $2
else
    echo "Usage: $0 <save|load> [snapshot_file]"
    exit 1
fi

