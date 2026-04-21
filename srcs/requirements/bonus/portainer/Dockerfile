FROM debian:12

RUN apt-get update && \
	apt-get install -y wget && \
	rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN wget https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz

RUN tar -xvf portainer-2.19.4-linux-amd64.tar.gz

WORKDIR /opt/portainer

EXPOSE 9000

CMD ["./portainer"]