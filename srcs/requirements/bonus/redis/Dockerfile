FROM debian:12

RUN apt update && \
	apt install -y redis-server && \
	rm -rf /var/lib/apt/lists/*

EXPOSE 6379

ENTRYPOINT ["redis-server", "--bind", "0.0.0.0", "--protected-mode", "no"]