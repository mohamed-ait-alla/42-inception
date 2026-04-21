FROM debian:12

RUN apt-get update && \
	apt-get install -y wget && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN wget https://github.com/google/cadvisor/releases/download/v0.56.2/cadvisor-v0.56.2-linux-amd64 -O cadvisor

RUN chmod +x cadvisor

EXPOSE 8080

CMD ["./cadvisor"]