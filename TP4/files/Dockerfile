FROM ubuntu

RUN apt update -y

RUN apt install -y apache2

COPY ./index.html /var/www/html/index.html

RUN mkdir /etc/apache2/logs/ 
