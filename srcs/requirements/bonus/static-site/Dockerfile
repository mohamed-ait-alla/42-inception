FROM debian:12

RUN	apt update && \
	apt install -y nginx && \
	rm -rf /var/lib/apt/lists/*


COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY website/	/var/www/html


CMD ["nginx" , "-g", "daemon off;"]