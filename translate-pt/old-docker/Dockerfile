# Base image
FROM ubuntu:22.04

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH_TO_MONARC_FO=/var/www/html/MonarcAppFO
ENV PATH_TO_MONARC_BO=/var/www/html/MonarcAppBO
ENV APPENV=local
ENV ENVIRONMENT=production
ENV COMPOSER_ALLOW_SUPERUSER=1

# MariaDB configuration
ENV DBHOST=localhost
ENV DBNAME_COMMON=monarc_common
ENV DBNAME_MASTER=monarc_master
ENV DBNAME_CLI=monarc_cli
ENV DBUSER_ADMIN=root
ENV DBPASSWORD_ADMIN=pwdPwd2020
ENV DBUSER_MONARC=sqlmonarcuser
ENV DBPASSWORD_MONARC=pwdPwd2020

# PHP configuration
ENV upload_max_filesize=200M
ENV post_max_size=50M
ENV max_execution_time=100
ENV max_input_time=223
ENV memory_limit=512M
ENV PHP_INI=/etc/php/8.1/apache2/php.ini
ENV XDEBUG_CFG=/etc/php/8.1/apache2/conf.d/20-xdebug.ini
ENV MARIA_DB_CFG=/etc/mysql/mariadb.conf.d/50-server.cnf

# Stats service
ENV STATS_PATH=/home/stats-service
ENV STATS_DB_NAME=statsservice
ENV STATS_DB_USER=statsserviceuser
ENV STATS_DB_PASSWORD=password

# Install base packages and PHP 8.1
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
        vim zip unzip git gettext curl gsfonts mariadb-server mariadb-client apache2 \
        php8.1 php8.1-cli php8.1-common php8.1-mysql php8.1-zip php8.1-gd php8.1-mbstring \
        php8.1-curl php8.1-xml php8.1-bcmath php8.1-intl php8.1-imagick php8.1-xdebug \
        sudo postgresql python3 python3-pip python3-venv nodejs npm mc screen && \
    apt-get clean

# MariaDB setup
RUN service mariadb start && \
    mysql -u root -e "CREATE USER '$DBUSER_MONARC'@'%' IDENTIFIED BY '$DBPASSWORD_MONARC';" && \
    mysql -u root -e "GRANT ALL PRIVILEGES ON * . * TO '$DBUSER_MONARC'@'%';" && \
    mysql -u root -e "FLUSH PRIVILEGES;" && \
    sed -i "s/skip-external-locking/#skip-external-locking/g" $MARIA_DB_CFG && \
    sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" $MARIA_DB_CFG && \
    sed -i "s/.*character-set-server.*/character-set-server = utf8mb4/" $MARIA_DB_CFG && \
    sed -i "s/.*collation-server.*/collation-server = utf8mb4_general_ci/" $MARIA_DB_CFG && \
    service mariadb restart

# PHP configuration
RUN for key in upload_max_filesize post_max_size max_execution_time max_input_time memory_limit; do \
    sed -i "s/^\($key\).*/\1 = 200M/" /etc/php/8.1/apache2/php.ini; done && \
    echo 'zend_extension=xdebug.so' > /etc/php/8.1/apache2/conf.d/20-xdebug.ini && \
    echo 'xdebug.mode=debug' >> /etc/php/8.1/apache2/conf.d/20-xdebug.ini && \
    echo 'xdebug.discover_client_host=1' >> /etc/php/8.1/apache2/conf.d/20-xdebug.ini

# Apache configuration
RUN a2enmod rewrite ssl headers && \
    sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf && \
    echo 'AcceptFilter https none' >> /etc/apache2/apache2.conf && \
    echo 'AcceptFilter http none' >> /etc/apache2/apache2.conf

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer self-update

# Install MONARC with dependency fix
RUN git clone --config core.fileMode=false https://github.com/monarc-project/MonarcAppFO $PATH_TO_MONARC_FO && \
    git clone --config core.fileMode=false https://github.com/monarc-project/MonarcAppBO $PATH_TO_MONARC_BO && \
    sed -i 's/"php": "\^7.4 || \^8.0"/"php": "\^7.4 || \^8.1"/' $PATH_TO_MONARC_FO/composer.json && \
    sed -i 's/"ocramius\/proxy-manager": "[^"]*"/"ocramius\/proxy-manager": "2.13.1"/' $PATH_TO_MONARC_FO/composer.json && \
    sed -i 's/"monarc\/core": "[^"]*"/"monarc\/core": "dev-master"/' $PATH_TO_MONARC_FO/composer.json && \
    cd $PATH_TO_MONARC_FO && composer update --no-interaction --with-all-dependencies -vvv 2>&1 | tee /var/www/html/MonarcAppFO/composer-debug.log && \
    mkdir -p module/Monarc && cd module/Monarc && \
    ln -sfn ./../../vendor/monarc/core Core && \
    ln -sfn ./../../vendor/monarc/frontoffice FrontOffice && \
    cd $PATH_TO_MONARC_FO && mkdir -p node_modules && cd node_modules && \
    git clone --config core.fileMode=false https://github.com/monarc-project/ng-client.git ng_client && \
    git clone --config core.fileMode=false https://github.com/monarc-project/ng-anr.git ng_anr

# Set up BO modules
RUN cd $PATH_TO_MONARC_BO && composer update --no-interaction -vvv 2>&1 | tee /var/www/html/MonarcAppBO/composer-debug.log && \
    mkdir -p module/Monarc && cd module/Monarc && \
    ln -sfn ./../../vendor/monarc/core Core && \
    ln -sfn ./../../vendor/monarc/backoffice BackOffice && \
    cd $PATH_TO_MONARC_BO && mkdir -p node_modules && cd node_modules && \
    git clone --config core.fileMode=false https://github.com/monarc-project/ng-backoffice.git ng_backoffice && \
    git clone --config core.fileMode=false https://github.com/monarc-project/ng-anr.git ng_anr

# Apache VirtualHost configuration
RUN echo '<VirtualHost *:80>' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    ServerName localhost' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    DocumentRoot /var/www/html/MonarcAppFO/public' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    <Directory /var/www/html/MonarcAppFO/public>' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '        DirectoryIndex index.php' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo 'Listen 8080' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '<VirtualHost *:8080>' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    ServerName localhost' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    DocumentRoot /var/www/html/MonarcAppBO/public' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    <Directory /var/www/html/MonarcAppBO/public>' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '        DirectoryIndex index.php' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-enabled/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-enabled/000-default.conf

# Expose ports
EXPOSE 80 8080 5000

# Start services
CMD ["apachectl", "-D", "FOREGROUND"]
