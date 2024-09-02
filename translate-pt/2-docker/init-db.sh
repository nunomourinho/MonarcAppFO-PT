#!/bin/bash
set -e

echo "Starting init-db.sh script..."

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to be ready..."
until mysql -h mariadb -u root -proot_password -e "SELECT 1" > /dev/null 2>&1; do
  echo "MariaDB is not ready yet. Sleeping..."
  sleep 5
done
echo "MariaDB is ready."

# Set MONARC_VERSION directly
MONARC_VERSION=$(curl --silent -H 'Content-Type: application/json' https://api.github.com/repos/monarc-project/MonarcAppFO/releases/latest | jq -r '.tag_name')

# Create MONARC user and databases if not already exist
echo "Creating MONARC user and databases if not exists..."
mysql -h mariadb -u root -proot_password <<EOF
CREATE USER IF NOT EXISTS 'monarc'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON * . * TO 'monarc'@'%';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS monarc_cli DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE IF NOT EXISTS monarc_common DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
EOF
echo "MONARC user and databases created."

# Initialize MONARC databases
echo "Initializing MONARC databases..."
if [ -z "$MONARC_VERSION" ]; then
    echo "Error: MONARC_VERSION is not set."
    exit 1
fi
mysql -h mariadb -u monarc -ppassword monarc_common < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_structure.sql
mysql -h mariadb -u monarc -ppassword monarc_common < /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/db-bootstrap/monarc_data.sql
echo "MONARC databases initialized."

# Copy and configure local.php
echo "Configuring MONARC database connection..."
cp /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php.dist /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
sed -i "s/'host' => 'localhost'/'host' => 'mariadb'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
sed -i "s/'user' => 'monarc'/'user' => 'monarc'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
sed -i "s/'password' => 'password'/'password' => 'password'/g" /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/config/autoload/local.php
echo "MONARC database connection configured."

# Migrate MONARC DB
echo "Migrating MONARC DB..."
php /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/vendor/robmorgan/phinx/bin/phinx migrate -c /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/module/Monarc/FrontOffice/migrations/phinx.php
php /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/vendor/robmorgan/phinx/bin/phinx migrate -c /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/module/Monarc/Core/migrations/phinx.php
echo "MONARC DB migration completed."

# Create initial user
echo "Creating initial MONARC user..."
php /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/vendor/robmorgan/phinx/bin/phinx seed:run -c /var/lib/monarc/releases/MonarcAppFO-$MONARC_VERSION/module/Monarc/FrontOffice/migrations/phinx.php
echo "Initial MONARC user created."

echo "init-db.sh script completed."
