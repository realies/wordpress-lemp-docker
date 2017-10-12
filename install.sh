#!/bin/bash

WP_ROOT="/var/www/wp/"	# wordpress location
USRID=1000		# can't be root
PORT=8080		# port to run the webserver on

if [ "$(ls -A $WP_ROOT 2> /dev/null)" ]; then
        echo "* Target directory ${WP_ROOT} not empty, exiting..."
else
        if [ ! -d ${WP_ROOT} ]; then
                echo "* Setting up folder structure..." && \
                mkdir -p ${WP_ROOT}
        fi
        echo "* Grepping latest Wordpress release..." && \
        WORDPRESS_DOWNLOAD=$(curl -fsL https://wordpress.org/download/release-archive/ | grep -Eo 'https://wordpress.org/wordpress-4.[0-9\.]{1,4}.tar.gz' | sed 's/\.tar\.gz//' | sort -nr | uniq | head -1) && \
        echo "* Downloading ${WORDPRESS_DOWNLOAD}.tar.gz..." && \
        curl -fL# $WORDPRESS_DOWNLOAD.tar.gz -o wordpress.tar.gz && \
        # or maybe just http://wordpress.org/latest.tar.gz
        echo "* Extracting to ${WP_ROOT}..." && \
        tar -xf wordpress.tar.gz -C ${WP_ROOT} --strip-components=1 && \
        echo "* Setting folder ownership..." && \
        chown ${USRID} ${WP_ROOT} && \
        echo "* Cleaning up..." && \
        rm wordpress.tar.gz && \
        echo "* Setting up MariaDB..." && \
        docker run --name mariadb -e MYSQL_ROOT_PASSWORD=secret -e MYSQL_DATABASE=wordpress -e MYSQL_USER=wordpress -e MYSQL_PASSWORD=secret -d mariadb:latest && \
        echo "* Setting up Nginx + PHP..." && \
        docker run -d --name nginx-php71 -u ${USRID}:0 -p ${PORT}:8080 -v ${WP_ROOT}:/var/www/html/ --link mariadb:mysql 1and1internet/ubuntu-16-nginx-php-7.1:latest && \
        echo "* Done"
fi
