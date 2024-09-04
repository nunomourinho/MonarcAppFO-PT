# Use official PHP image with Apache
FROM php:8.1-apache

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get dist-upgrade -y && \
    apt-get autoremove -y && \
    apt-get clean

# Install system dependencies
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    git \
    gettext \
    curl \
    jq \
    mc \
    screen \
    bash \
    nano \
    mariadb-client \
    python3 \
    python3-pip \
    python3-venv \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && apt-get clean

# Disable module status
RUN a2dismod status

# Enable Apache modules
RUN a2enmod ssl rewrite headers

# Copy Apache configuration
COPY helper/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy .env file
COPY .env /docker-entrypoint-initdb.d/.env

# PHP configuration
RUN echo "upload_max_filesize = 200M\n\
post_max_size = 50M\n\
max_execution_time = 100\n\
max_input_time = 223\n\
memory_limit = 2048M\n\
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE & ~E_WARNING" > /usr/local/etc/php/php.ini

# Install MONARC
ENV PATH_TO_MONARC=/var/lib/monarc/fo
ENV PATH_TO_MONARC_DATA=/var/lib/monarc/fo-data

RUN mkdir -p /var/lib/monarc/releases/ && \
    MONARC_VERSION=$(curl --silent -H 'Content-Type: application/json' https://api.github.com/repos/monarc-project/MonarcAppFO/releases/latest | jq  -r '.tag_name') && \
    MONARCFO_RELEASE_URL="https://github.com/monarc-project/MonarcAppFO/releases/download/$MONARC_VERSION/MonarcAppFO-$MONARC_VERSION.tar.gz" && \
    curl -sL $MONARCFO_RELEASE_URL -o /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL` && \
    mkdir /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL | sed 's/.tar.gz//'` && \
    tar -xzf /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL` -C /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL | sed 's/.tar.gz//'` && \
    ln -s /var/lib/monarc/releases/`basename $MONARCFO_RELEASE_URL | sed 's/.tar.gz//'` $PATH_TO_MONARC && \
    mkdir -p $PATH_TO_MONARC_DATA/cache $PATH_TO_MONARC_DATA/DoctrineORMModule/Proxy $PATH_TO_MONARC_DATA/LazyServices/Proxy $PATH_TO_MONARC_DATA/import/files && \
    ln -s $PATH_TO_MONARC_DATA $PATH_TO_MONARC/data && \
    chown -R www-data:www-data /var/lib/monarc

# Create a virtual environment for Python
RUN python3 -m venv /usr/src/app/venv

# Activate the virtual environment and install Python dependencies
COPY helper/requirements.txt /usr/src/app/requirements.txt
RUN /usr/src/app/venv/bin/pip install --upgrade pip && \
    /usr/src/app/venv/bin/pip install -r /usr/src/app/requirements.txt

# Copy database initialization script and the Python translation script
COPY helper/init-db.sh /docker-entrypoint-initdb.d/init-db.sh
COPY helper/3-translate-db.py /usr/src/app/3-translate-db.py
COPY helper/final_translated_strings.csv /usr/src/app/final_translated_strings.csv
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh

# Set the working directory
WORKDIR /var/lib/monarc/fo

# Expose port 80
EXPOSE 80


CMD ["/bin/bash", "-c", "/docker-entrypoint-initdb.d/init-db.sh && apache2-foreground"]

