# Alpine Image for Nginx and PHP

# NGINX x ALPINE.
FROM nginx:1.17.5-alpine

# MAINTAINER OF THE PACKAGE.
LABEL maintainer="Tarikh Agustia <agustia.tarikh150@gmail.com"

# INSTALL SOME SYSTEM PACKAGES.
RUN apk --update --no-cache add ca-certificates \
    bash \
    supervisor

# trust this project public key to trust the packages.
ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

# CONFIGURE ALPINE REPOSITORIES AND PHP BUILD DIR.
ARG PHP_VERSION=7.3
ARG ALPINE_VERSION=3.9
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/community" >> /etc/apk/repositories && \
    echo "https://dl.bintray.com/php-alpine/v${ALPINE_VERSION}/php-${PHP_VERSION}" >> /etc/apk/repositories

# INSTALL PHP AND SOME EXTENSIONS. SEE: https://github.com/codecasts/php-alpine
RUN apk add --no-cache --update php-fpm \
    php \
    nodejs \
    npm \
    argon2-dev \
    libargon2 \
    php-openssl \
    php-pdo \
    php-pdo_mysql \
    php-mbstring \
    php-phar \
    php-session \
    php-dom \
    php-ctype \
    php-gd \
    php-zip \
    php-zlib \
    php-json \
    php-curl \
    php-iconv \
    php-xmlreader \
    php-sockets \
    php-redis \
    php-xml && \
    ln -s /usr/bin/php7 /usr/bin/php

# CONFIGURE WEB SERVER.
RUN mkdir -p /var/www && \
    mkdir -p /run/php && \
    mkdir -p /run/nginx && \
    mkdir -p /var/log/supervisor && \
    mkdir -p /etc/nginx/sites-enabled && \
    mkdir -p /etc/nginx/sites-available && \
    rm /etc/nginx/nginx.conf && \
    rm /etc/php7/php-fpm.d/www.conf && \
    rm /etc/php7/php.ini

# INSTALL COMPOSER.
COPY --from=composer:1.10 /usr/bin/composer /usr/bin/composer

# ADD START SCRIPT, SUPERVISOR CONFIG, NGINX CONFIG AND RUN SCRIPTS.
ADD start.sh /start.sh
ADD deploy/supervisor/supervisord.conf /etc/supervisord.conf
ADD deploy/nginx/nginx.conf /etc/nginx/nginx.conf
ADD deploy/nginx/site.conf /etc/nginx/sites-available/default.conf
ADD deploy/php/php.ini /etc/php7/php.ini
ADD deploy/php-fpm/www.conf /etc/php7/php-fpm.d/www.conf
RUN chmod 755 /start.sh

# Copy Source Code
COPY . /var/www

# SET THE WORK DIRECTORY.
WORKDIR /var/www

# SET THE WORK DIRECTORY.
RUN npm install && \
    npm run prod --section=app && \
    npm run prod --section=console && \
    rm -rf node_modules

# Create Cache directories
RUN mkdir -p storage/framework/cache/data && \
    mkdir -p storage/framework/sessions && \
    mkdir -p storage/framework/views && \
    mkdir -p storage/logs && \
    chmod 777 storage/logs && \
    chmod g+s storage && \
    chown -Rf nginx:nginx storage && \
    chmod 777 -Rf storage

RUN umask 002

# EXPOSE PORTS!
ARG NGINX_HTTP_PORT=80
ARG NGINX_HTTPS_PORT=443
EXPOSE ${NGINX_HTTPS_PORT} ${NGINX_HTTP_PORT}


RUN composer global require hirak/prestissimo && \
    composer install --optimize-autoloader --no-dev

# Link Storage
RUN php artisan storage:link

# KICKSTART!
CMD ["/start.sh"]
