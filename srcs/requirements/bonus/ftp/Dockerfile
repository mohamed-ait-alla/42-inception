FROM debian:12

RUN apt update && \
	apt install -y vsftpd && \
	rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 21

ENTRYPOINT ["/entrypoint.sh"]