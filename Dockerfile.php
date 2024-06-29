FROM php:8.1-fpm

RUN docker-php-ext-install mysqli
RUN apt update && apt install -y zlib1g-dev libpng-dev libzip-dev libicu-dev libc-client-dev libkrb5-dev && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install gd
RUN docker-php-ext-install zip
RUN docker-php-ext-install intl
RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl && docker-php-ext-install imap
RUN docker-php-ext-install calendar
