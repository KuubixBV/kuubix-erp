# How to develop for Dolibarr

## Step 1

Download the desired version of Dolibarr. This can be achieved by running the `bash ./download-dolibarr.sh` script. The script will ask for a version to be downloaded. The current used version for Kuubix will be set as default. Feel free to enter another version if needed.

## Step 2

Create a `.env` file. You can have a look in the `example.env` file to set up the `.env`.

## Step 3

After downloading the Dolibarr files and setting up our .env file, we can start our services. These services are `MariaDB, PHPMyAdmin, PHP and NGINX`. Start the docker by entering the following command:

`docker compose up -d`

## Step 4 (optional)

DB IMPORT?

## Step 5

Next surf to your localhost on the port you have setup in the `.env` file. You should now see the Dolibarr setup page. When you come to the fileconf setup part, fill in `172.200.0.2` under Database server. Next fill in `root` under Login and use the password set in the `.env` file from the database.

## Step 6

All good!
