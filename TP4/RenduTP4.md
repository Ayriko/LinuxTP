# TP4 : Conteneurs

Mettre à jour la sync date :
```bash
[rocky@docker1 compose]$ sudo timedatectl set-ntp true
[sudo] password for rocky:
[rocky@docker1 compose]$ sudo timedatectl  set-timezone Europe/Paris
[rocky@docker1 compose]$ sudo systemctl restart chronyd
```

## I/ Docker

### 1.Installation

```bash
[rocky@docker1 ~]$ sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
Adding repo from: https://download.docker.com/linux/centos/docker-ce.repo
[rocky@docker1 ~]$ sudo dnf install docker-ce docker-ce-cli containerd.io
[...]
Complete!
[rocky@docker1 ~]$ sudo systemctl start docker
[rocky@docker1 ~]$ sudo systemctl status docker
● docker.service - Docker Application Container Engine
     Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
     Active: active (running) since Thu 2022-11-24 10:44:50 CET; 4s ago
TriggeredBy: ● docker.socket
[...]
[rocky@docker1 ~]$ sudo systemctl enable docker
Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
[rocky@docker1 ~]$ sudo usermod -aG docker $(whoami)
```

Pour la suite, on relance d'abord le ssh pour que l'ajout au groupe docker soit pris en compte.

### 2. Vérification de l'install

Toutes les commandes semblent ok, l'install aussi donc.

### 3. Lancement de conteneurs

```bash
[rocky@docker1 ~]$ docker run --name web -d --rm -v /home/rocky/serv.conf:/etc/nginx/conf.d/serv.conf -v /home/rocky/index.html:/usr/share/nginx/html/index.html -p 8888:80 --cpus="1" -m 500m nginx 
```
```bash
[rocky@docker1 ~]$ docker ps -a
CONTAINER ID   IMAGE     COMMAND                  CREATED             STATUS                           
98fc4c908ff2   nginx     "/docker-entrypoint.…"   32 seconds ago      Up 31 seconds                  
PORTS                                   NAMES  
0.0.0.0:8888->80/tcp, :::8888->80/tcp   web
```

## II/ Images

Création d'un dossier de travail et du dockerfile :
```bash
[rocky@docker1 ~]$ mkdir work
[rocky@docker1 ~]$ cd work
[rocky@docker1 work]$ sudo vim Dockerfile
[sudo] password for rocky:
-> 
FROM ubuntu

RUN apt update -y

RUN apt install -y apache2

COPY ./index.html /var/www/html/index.html

RUN mkdir /etc/apache2/logs/

```
On créé un simple html custom pour la page index de Apache2 :
```bash
[rocky@docker1 work]$ sudo vim index.html
-> 
```
```html

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>

<body>
    <h1>Salut je suis la page html du service Apache qui s'affiche actuellement</h1>
</body>

</html>
```

On prépare aussi un ficher de conf minimal pour apache2 dans le docker :

```bash
[rocky@docker1 work]$ sudo vim apache2.conf
ServerName 127.0.0.1
Listen 80
LoadModule mpm_event_module "/usr/lib/apache2/modules/mod_mpm_event.so"
# LoadModule mime_module "/usr/lib/apache2/modules/mod_mime.so"
LoadModule dir_module "/usr/lib/apache2/modules/mod_dir.so"
LoadModule authz_core_module "/usr/lib/apache2/modules/mod_authz_core.so"
DirectoryIndex index.html
DocumentRoot "/var/www/html/"
ErrorLog "logs/error.log"
LogLevel warn
```
On peut voir ici l'intéret de créer un dossier logs dans le dockerfile, avec la ligne ErrorLog.

On va maintenant build le dockerfile :
```bash
[rocky@docker1 work]$ docker build . -t my_apache
Sending build context to Docker daemon  4.096kB
Step 1/5 : FROM ubuntu
 ---> a8780b506fa4
Step 2/5 : RUN apt update -y
 ---> Using cache
 ---> 905a4ca75604
Step 3/5 : RUN apt install -y apache2
 ---> Using cache
 ---> 16e0dbbd5263
Step 4/5 : COPY ./index.html /var/www/html/index.html
 ---> Using cache
 ---> 4e3260de9565
Step 5/5 : RUN mkdir /etc/apache2/logs/
 ---> Using cache
 ---> a5ca7f7f9459
Successfully built a5ca7f7f9459
Successfully tagged my_apache:latest
```


Une fois build, on peut le lancer avec :
```bash
docker run --rm -p 8888:80 -v $(pwd)/apache2.conf:/etc/apache2/apache2.conf my_apache apache2 -DFOREGROUND
```
Grâce au `-DFOREGROUND` apache2 se lance en fond et ne ferme pas le docker immédiatement.
On importe aussi le fichier de conf.

On peut désormais y accéder depuis 10.104.1.11:8888


[Dockerfile](files/Dockerfile)

## III/ Docker-compose

On crée les dossiers et fichiers nécessaires :

```bash
[rocky@docker1 ~]$ mkdir compose
[rocky@docker1 ~]$ cd compose/
[rocky@docker1 compose]$ mkdir app
[rocky@docker1 compose]$ vim Dockerfile
```
```bash
FROM ubuntu:22.04

RUN apt update -y && \
    apt install git -y && \
    apt install golang -y

RUN git clone https://github.com/Ayriko/Compendium.git /app

WORKDIR /app

RUN go build

CMD [ "/usr/bin/go", "run", "./main.go" ]
```
```bash
[rocky@docker1 compose]$ vim docker-compose.yml
```
```bash
version: "3.8"

services:
  compendium:
    image: compendium
    restart: always
    ports:
      - '8080:8080'
```

On peut désormais le build :

```bash
[rocky@docker1 compose]$ docker build . -t compendium
Sending build context to Docker daemon  3.072kB
Step 1/6 : FROM ubuntu:22.04
 ---> a8780b506fa4
Step 2/6 : RUN apt update -y &&     apt install git -y &&     apt install golang -y
 ---> Using cache
 ---> 8f77d0eb0e63
Step 3/6 : RUN git clone https://github.com/Ayriko/Compendium.git /app
 ---> Using cache
 ---> a2aee8274d7a
Step 4/6 : WORKDIR /app
 ---> Using cache
 ---> 04c9d722d526
Step 5/6 : RUN go build
 ---> Using cache
 ---> 70ea15605522
Step 6/6 : CMD [ "/usr/bin/go", "run", "./main.go" ]
 ---> Using cache
 ---> e3cc60a54332
Successfully built e3cc60a54332
Successfully tagged compendium:latest
```

Et finalement lancer le docker-compose :

```bash
[rocky@docker1 compose]$ docker compose up
[+] Running 1/0
 ⠿ Container compose-compendium-1  Created                                                       0.0s
Attaching to compose-compendium-1
compose-compendium-1  | # github.com/mattn/go-sqlite3
compose-compendium-1  | sqlite3-binding.c: In function 'sqlite3SelectNew':
compose-compendium-1  | sqlite3-binding.c:128049:10: warning: function may return address of local variable [-Wreturn-local-addr]
compose-compendium-1  | 128049 |   ret
[...]
```

Le service est accessible depuis `10.104.1.11:8080`

[Dockerfile de l'app](app/Dockerfile)  
[docker-compose de l'app](app/docker-compose.yml)