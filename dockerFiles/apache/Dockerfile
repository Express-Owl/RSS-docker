FROM php:8.3-apache


RUN apt-get update && \
    apt-get install -y git && \
    # récupération des dépendencies de php-gd
    apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev --no-install-recommends && \ 
    rm -rf /var/lib/apt/lists/*

#installation des packages aditionnels php-gd et mysqli
RUN docker-php-ext-install mysqli && docker-php-ext-enable mysqli && \
    docker-php-ext-configure gd --with-jpeg --with-freetype && \
    docker-php-ext-install -j$(nproc) gd

# récupération du code source de leed
WORKDIR /var/www/html

RUN git config --global --add safe.directory /var/www/html && \
    git clone https://github.com/LeedRSS/Leed ./ && \
    cd /var/www/html && \
    git checkout tags/v1.14.0

# pour que php puisse accèder au dossier leed correctement
RUN chmod -R 775 /var/www/html && \
    chown -R www-data:www-data /var/www/html

EXPOSE 80