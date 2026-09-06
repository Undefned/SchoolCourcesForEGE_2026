FROM php:8.2-apache

# Устанавливаем расширения для PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_pgsql

# Включаем mod_rewrite
RUN a2enmod rewrite

# Настраиваем PHP для разработки
RUN echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "display_errors = 1" >> /usr/local/etc/php/conf.d/custom.ini \
    && echo "display_startup_errors = 1" >> /usr/local/etc/php/conf.d/custom.ini

# Убираем предупреждение Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

WORKDIR /var/www/html