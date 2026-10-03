FROM php:8.4-apache

# ------------------------------------------------------------
# System dependencies
# ------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libonig-dev \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# PHP extensions
# ------------------------------------------------------------
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    && docker-php-ext-install \
    pdo_sqlite \
    gd \
    curl \
    mbstring

# ------------------------------------------------------------
# Apache configuration
# ------------------------------------------------------------

# Enable modules used by QR Track
RUN a2enmod rewrite headers

# Allow QR Track's .htaccess to use rewrite rules
RUN printf '%s\n' \
    '<Directory /var/www/html>' \
    '    Options FollowSymLinks' \
    '    AllowOverride All' \
    '    Require all granted' \
    '</Directory>' \
    > /etc/apache2/conf-available/qr-track.conf \
    && a2enconf qr-track

# ------------------------------------------------------------
# Composer
# ------------------------------------------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# ------------------------------------------------------------
# Application
# ------------------------------------------------------------
WORKDIR /var/www/html

COPY . /var/www/html/

# Install application dependencies
RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

# ------------------------------------------------------------
# Persistent storage
# ------------------------------------------------------------
RUN mkdir -p /data/db /data/tmp \
    && chown -R www-data:www-data /data \
    && chmod -R 775 /data \
    && chown -R www-data:www-data /var/www/html

# ------------------------------------------------------------
# Apache
# ------------------------------------------------------------
EXPOSE 80

CMD ["apache2-foreground"]
