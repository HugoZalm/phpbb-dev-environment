
FROM php:8.3-apache

RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    unzip \
    git \
    && docker-php-ext-configure gd \
       --with-freetype --with-jpeg \
    && docker-php-ext-install \
       mysqli pdo_mysql mbstring intl \
       gd zip opcache \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*
