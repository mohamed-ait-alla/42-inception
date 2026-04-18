FROM debian:12

RUN apt update && \
	apt install -y \
	php-cli \
	php-mysql \
	wget \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

RUN wget -O /var/www/html/index.php \
	https://www.adminer.org/latest.php

EXPOSE 8080

ENTRYPOINT ["php", "-S", "0.0.0.0:8080"]