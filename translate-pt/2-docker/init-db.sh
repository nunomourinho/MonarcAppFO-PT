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

# Set MONARC_VERSION directly
#MONARC_VERSION=$(curl --silent -H 'Content-Type: application/json' https://api.github.com/repos/monarc-project/MonarcAppFO/releases/latest | jq -r '.tag_name')


MONARC_VERSION="v2.12.7-p2"

# Create MONARC user and databases if not already exist
echo "Creating MONARC user and databases if not exists..."
mysql -h mariadb -u root -p${MYSQL_ROOT_PASSWORD} <<EOF
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON * . * TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;

#DROP DATABASE monarc_cli;
#DROP DATABASE ${MYSQL_DATABASE};

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
mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_structure.sql
mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE} < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_data.sql

#mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} monarc_cli < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_structure.sql
#mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} monarc_cli < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_data.sql


echo "MONARC databases initialized."

# Copy and configure local.php
echo "Configuring MONARC database connection..."
cp /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php.dist /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php


# Update the host, user, and password in local.php
sed -i "s/'host' => '.*'/'host' => 'mariadb'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
sed -i "s/'user' => '.*'/'user' => '${MYSQL_USER}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
sed -i "s/'password' => '.*'/'password' => '${MYSQL_PASSWORD}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
#sed -i "s/'dbname' => '.*'/'dbname' => '${MYSQL_DATABASE}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php


# Update the host, user, and password in local.php
#sed -i "s/'host' => '.*'/'host' => 'mariadb'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/global.php
#sed -i "s/'user' => '.*'/'user' => '${MYSQL_USER}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/global.php
#sed -i "s/'password' => '.*'/'password' => '${MYSQL_PASSWORD}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/global.php
#sed -i "s/'dbname' => '.*'/'dbname' => '${MYSQL_DATABASE}'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/global.php

# Migrate MONARC DB
echo "Migrating MONARC DB..."

cd /var/lib/monarc/fo
echo php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/FrontOffice/migrations/phinx.php
php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/FrontOffice/migrations/phinx.php || exit 0

echo "MONARC DB migration completed."

# Create initial user
echo "Creating initial MONARC user..."
echo php ./vendor/robmorgan/phinx/bin/phinx seed:run -c module/Monarc/FrontOffice/migrations/phinx.php
php ./vendor/robmorgan/phinx/bin/phinx seed:run -c module/Monarc/FrontOffice/migrations/phinx.php || exit 0
echo "Initial MONARC user created."

echo php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/Core/migrations/phinx.php
php ./vendor/robmorgan/phinx/bin/phinx migrate -c module/Monarc/Core/migrations/phinx.php || exit 0
echo "MONARC DB migration completed fase II."


echo "init-db.sh script completed."
