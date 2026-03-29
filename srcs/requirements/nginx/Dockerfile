FROM debian:12

RUN apt-get update && apt-get install -y nginx openssl && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 \
-keyout /etc/nginx/ssl/nginx.key \
-out /etc/nginx/ssl/nginx.crt \
-subj "/C=FR/ST=French/L=Paris/O=42/OU=42/CN=mait-all.42.fr"

COPY conf/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/www/html
RUN echo "<h1>HTTPS is working!...</h1>" > /var/www/html/index.html

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
