#!/bin/bash
set -e

# Load environment variables from .env file
export $(grep -v '^#' /docker-entrypoint-initdb.d/.env | xargs)

echo "Starting init-db.sh script..."

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h mariadb -u root -p${MYSQL_ROOT_PASSWORD} -e "SELECT 1" > /dev/null 2>&1; do
  echo "MariaDB is not ready yet. Sleeping..."
  sleep 5
done
echo "MariaDB is ready."

MONARC_VERSION=$(curl --silent -H 'Content-Type: application/json' https://api.github.com/repos/monarc-project/MonarcAppFO/releases/latest | jq -r '.tag_name')

# Create MONARC user and databases if not already exist
echo "Creating MONARC user and databases if not exists..."
mysql -h mariadb -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON * . * TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS monarc_cli DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE} DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
EOF
echo "MONARC user and databases created."

# Initialize MONARC databases
echo "Initializing MONARC databases..."
if [ -z "$MONARC_VERSION" ]; then
    echo "Error: MONARC_VERSION is not set."
    exit 1
fi

# Initialize MONARC databases
echo "Initializing MONARC databases..."
ls  /var/lib/monarc/releases/
echo $MONARC_VERSION/

mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_structure.sql
mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_data.sql

echo "MONARC databases initialized."


# Copy and configure local.php
echo "Configuring MONARC database connection..."
cp /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php.dist /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php


# Update the host, user, and password in local.php
sed -i "s/'host' => '.*'/'host' => 'mariadb'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
sed -i "s/'user' => '.*'/'user' => '${MYSQL_USER}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
sed -i "s/'password' => '.*'/'password' => '${MYSQL_PASSWORD}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php


# Run migration and seed
echo "Migrating and seeding MONARC database..."
php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/FrontOffice/migrations/phinx.php
php ./vendor/robmorgan/phinx/bin/phinx seed:run -c module/Monarc/FrontOffice/migrations/phinx.php
php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/Core/migrations/phinx.php

echo "Database migration and seeding completed."

# Run the Python translation script using the virtual environment
echo "Running 3-translate-db.py to translate the database..."
/usr/src/app/venv/bin/python /usr/src/app/3-translate-db.py && exit 0
echo "Database translation completed."

echo "init-db.sh script completed."
