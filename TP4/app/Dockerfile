FROM ubuntu:22.04

RUN apt update -y && \
    apt install git -y && \
    apt install golang -y

RUN git clone https://github.com/Ayriko/Compendium.git /app

WORKDIR /app

RUN go build

CMD [ "/usr/bin/go", "run", "./main.go" ]