# Projet final Linux - Avrae bot discord

# MOISKA Aymeric

# I/ Installation et configuration de la solution

## 1) Prérequis

Pour le bot que nous allons installer, comme pour les services secondaires qui viendront, nous allons utiliser 3 machines sous rocky linux 9. (6 si la réplication était implémentée).  
Elles sont à configurer au préalable avec une ip propre dans un même réseau (ici 10.201.1.0/24), une connexion ssh, un hostname précis et leurs paquets à jour. D'autres configurations viendront par la suite.

Prerequis pour Avrae  

- [Discord](https://discordapp.com/) account.
- [Dicecloud v1](https://v1.dicecloud.com) account - do NOT register with Google, create a normal account.
- [Dicecloud v2](https://dicecloud.com) account - do NOT register with Google, create a normal account.
- [Google Drive Service Account](https://gspread.readthedocs.io/en/latest/oauth2.html).
  - Follow steps 1-7 in the **For Bots: Using Service Account** portion. The contents of this JSON file will be needed

## 2) Installation

**Dans la machine principale qui va host la solution :**  

- installation de docker :

  ```bash
  [rocky@Avrae ~]$ sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  Adding repo from: https://download.docker.com/linux/centos/docker-ce.repo
  [rocky@Avrae ~]$ sudo dnf install docker-ce docker-ce-cli containerd.io
  [...]
  Complete!
  [rocky@Avrae ~]$ sudo systemctl start docker
  [rocky@Avrae ~]$ sudo systemctl status docker
  ● docker.service - Docker Application Container Engine
      Loaded: loaded (/usr/lib/systemd/system/docker.service; disabled; vendor preset: disabled)
      Active: active (running) since Thu 2022-11-24 10:44:50 CET; 4s ago
  TriggeredBy: ● docker.socket
  [...]
  [rocky@Avrae ~]$ sudo systemctl enable docker
  Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
  [rocky@Avrae ~]$ sudo usermod -aG docker $(whoami)
  ```

- Pour la suite, on relance d'abord le ssh pour que l'ajout au groupe docker soit pris en compte.  

- installer le paquet git :

   ```bash
  [rocky@Avrae]$ sudo dnf install git
  [...]
  ```

- puis à l 'emplacement souhaité :

  ```bash
  [rocky@Avrae]$ sudo git clone https://github.com/avrae/avrae.git
  [...]
  [rocky@Avrae]$ cd avrae
  ```

- nous sommes désormais dans notre dossier de travail principal pour ce qui va arriver par la suite  
  
## 3) Configuration

  **Avant même de modifier la solution elle a besoin de certaines variables à récupérer et bien sur d'un bot discord qui la portera :**

- Dicecloud :
  - Click Username in top left top open Account page
  - `DICECLOUD_USER` is the login username
  - `DICECLOUD_PASS` is your password (recommended to use a dedicated bot account with a random generated password)
  - `DICECLOUD_TOKEN` is the `API KEY` revealed by `SHOW`
- Dicecloud v2 :
  - Click gear in top left top open Account page
  - `DICECLOUDV2_USER` is the login username
  - `DICECLOUDV2_PASS` is your password (recommended to use a dedicated bot account with a random generated password)
- Google :
  - save the json file obtained earlier in the root project directory as `avrae-google.json`.
- Discord Id:
  - `User Settings` (cog icon) > `Advanced`, enable "Developer Mode".
  - Right-click your name in the user list and `Copy ID`, this is your `DISCORD_OWNER_USER_ID` below.
  - Create a server for yourself to test with: big `+` icon, `Create a server`.
- Discord bot -> création et token :
  - Go to the [Discord Developer Portal](https://discordapp.com/developers/).
  - `New Application`, give it a cool name, `Create`.
  - Copy the `Application ID` from `General Information`, you'll need this shortly.
  - `Bot` > `Add Bot`.
  - (Optional but recommended): Switch off `Public Bot` so only you can add this bot to servers.
  - Scroll down to `Privileged Gateway Intents`, and enable the switches to the right of `Server Members Intent` and `Message Content Intent`.
  - `Click to reveal token`, this is your `DISCORD_BOT_TOKEN` below.
  - Invite your bot to your
      server: `https://discordapp.com/oauth2/authorize?permissions=274878295104&scope=bot&client_id=1234`, replacing `1234` with your bot's `Application ID`. Make sure you select the correct server!

**Nous allons désormais créer le ficher d'environnement pour notre container :**

```bash
[rocky@Avrae avrae]$ mkdir docker
[rocky@Avrae avrae]$ sudo vim docker/env
DISCORD_BOT_TOKEN=MTA0NzgxODU1MzA3Nzc5MjgzMA.G2lcSw.UtykKvT_OT3yuBdlpVz7giCJ3OUMhSOvXNv6kQ
DICECLOUD_USER=ayriko-discordBot
DICECLOUD_PASS=Ayriko2022!
DICECLOUD_TOKEN=iG8kFk5dvSDNys7tAfeAx5FZtWhunb

DICECLOUDV2_USER=Ayriko
DICECLOUDV2_PASS=Ayriko2022!

# set these to these literal values
MONGO_URL=mongodb://root:topsecret@mongo:27017
REDIS_URL=redis://redis:6379/0

# set this to the contents of the JSON file downloaded in the Google Drive Service Account step
GOOGLE_SERVICE_ACCOUNT=
```

C'est ici ma configuration, ce sera différent pour vous.  
Et à partir de là le bot est déjà fonctionnel, si vous fouillez le contenu du dossier avrae vous verrez par exemple que le Dockerfile ou le docker-compose.yml sont déjà présent et configurez.  

**Toujours dans notre dossier de travail, on peut lancer la solution avec :**

```bash
[rocky@Avrae avrae]$ docker compose up --build
```

Cela prendra un peu temps au départ pour récupérer et installer tout ce qu'il faut mais vous verrez le bot en ligne sur votre discord et il répondra au commande comme !ping qui permet rapidement de savoir si il est réactif.  

# II/ Personnalisation

## 1) Installation et configuration de mongodb sur une autre machine

On va modifier notre solution actuelle en sortant mongodb du container pour qu'il soit host sur une machine dédiée.

**Seconde machine dans le réseau**

- On ajoute un répo pour l'installer car il n'est pas dans les défauts de rocky linux 9 :

 ```bash
  [rocky@AvraeDB]$ sudo vim /etc/yum.repos.d/mongodb-org-6.0.repo
    [mongodb-org-6.0]
    name=MongoDB Repository
    baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/x86_64/
    gpgcheck=1
    enabled=1
    gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
  [rocky@AvraeDB]$ sudo dnf install mongodb-org -y
  [...]
 ```

- On démarre et active le service :

 ```bash
 [rocky@AvraeDB]$ sudo systemctl start mongod
 [rocky@AvraeDB]$ sudo systemctl enable mongod
 ```

- Vérification de l'état avec :

 ```bash
[rocky@AvraeDB]$ sudo systemctl status mongod
 ● mongod.service - MongoDB Database Server
     Loaded: loaded (/usr/lib/systemd/system/mongod.service; enabled; vendor preset: disabled)
     Active: active (running) since Thu 2022-12-08 12:52:49 CET; 9h ago
       Docs: https://docs.mongodb.org/manual
   Main PID: 912 (mongod)
     Memory: 198.6M
        CPU: 3min 50.295s
     CGroup: /system.slice/mongod.service
             └─912 /usr/bin/mongod -f /etc/mongod.conf

Dec 08 12:52:47 AvraeDB systemd[1]: Starting MongoDB Database Server...
Dec 08 12:52:47 AvraeDB mongod[812]: about to fork child process, waiting until server is ready for connections.
Dec 08 12:52:47 AvraeDB mongod[912]: forked process: 912
Dec 08 12:52:49 AvraeDB mongod[812]: child process started successfully, parent exiting
Dec 08 12:52:49 AvraeDB systemd[1]: Started MongoDB Database Server.
 ```

- Connexion au service et création d'un user avec privilège :  
(mongodb nous propose aussi d'activer le monitoring pour la db on peut accepter et utiliser la commande qu'il donne si voulu)

```bash
[rocky@AvraeDB]$ mongosh
use admin
db.createUser({user: "avraeBot", pwd: "avraepwd", roles: [{ role: 'userAdminAnyDatabase', db: 'admin' }, { role: 'readWriteAnyDatabase', db: 'admin' }]})
exit
```

On peut vérifier sa création avec `db.getUsers()`

- Pour bien activer l'authentification :

```bash
[rocky@AvraeDB]$ sudo vim /etc/mongod.conf
-> uncomment security
-> ajout de la ligne direct en dessous : 
  authorization: "enabled"
```

! attention il faut deux espaces avant authorization pour que la conf soit bien lu !

- dans le même fichier de conf, sous "net", on remplace :

```bash
bindIP 127.0.0.1 -> 0.0.0.0
```

- sauvegarder le ficher et redémarrer le service mongod :

```bash
[rocky@AvraeDB]$ sudo systemctl restart mongod
```

- ouverture du port 27017 :

```bash
[rocky@AvraeDB]$ sudo firewall-cmd --add-port=27017/tcp --permanent
success
[rocky@AvraeDB]$ sudo firewall-cmd --reload
success
```

**Notre mongodb sur une machine dédié est maintenant prêt, on va modifier la conf de notre docker pour qu'il s'y connecte à distance.**

**Machine principale avec avrae**

- si le bot est en ligne -> `docker compose down`
- on edit l'url de mongo dans le docker/env:

```bash
MONGO_URL=mongodb://root:topsecret@mongo:27017 -> MONGO_URL=mongodb://avraeBot:avraepwd@10.201.1.12:27017
```

- on edit notre docker-compose.yml pour qu'il ressemble à ça :

```bash
version: '3'

services:
  bot:
    image: avrae
    build:
      context: .
      args:
        DBOT_ARGS: test
        ENVIRONMENT: development
    depends_on:
      - redis
    env_file:
      - ./docker/env
    environment:
      DBOT_ARGS: test
      ENVIRONMENT: development

  redis:
    image: redis:5
    ports:
      - 58379:6379
    volumes:
      - redis:/data

volumes:
  redis:
```

- On peut maintenant relancer Avrae avec un nouveau build qui prendra nos modifications en compte.  
Si le service mongo n'est pas lancé sur l'autre machine, on aura le message suivant :

```bash
 pymongo.errors.ServerSelectionTimeoutError: 10.201.1.12:27017: [Errno 111] Connection refused, Timeout: 30s, Topology Description: <TopologyDescription id: 638a9c4686c04feee97fc6ad, topology_type: Single, servers: [<ServerDescription ('10.201.1.12', 27017) server_type: Unknown, rtt: None, error=AutoReconnect('10.201.1.12:27017: [Errno 111] Connection refused')>]>
```

En se connectant localement sur la db avec l'utilisateur créé plus tôt, on peut aussi voir l'apparition de la collection avrae et des nombreuses tables qui vont avec.

## 2) Installation et configuration de Redis sur une autre machine

Comme pour mongodb, on va sortir le service redis du container pour qu'il soit host sur une machine dédiée et joint à distance.

- Installation de redis

```bash
[rocky@AvraeRedis ~]$ sudo dnf install redis
[sudo] password for rocky:
Last metadata expiration check: 0:53:35 ago on Tue 06 Dec 2022 05:34:39 PM CET.
Dependencies resolved.
[...]
```

- Configuration de redis

```bash
[rocky@AvraeRedis ~]$ sudo vim /etc/redis/redis.conf
-> uncommend supervised systemd
-> change bind address en 0.0.0.0
-> protected-mode to no
-> security, ligne requirepass foobared -> changer foobared par mdp
```

- Activation du service

```bash
[rocky@AvraeRedis ~]$ sudo systemctl start redis.service
[rocky@AvraeRedis ~]$ sudo systemctl status redis.service
● redis.service - Redis persistent key-value database
     Loaded: loaded (/usr/lib/systemd/system/redis.service; disabled; vendor preset: disabled)
    Drop-In: /etc/systemd/system/redis.service.d
             └─limit.conf
     Active: active (running) since Tue 2022-12-06 18:33:07 CET; 6s ago
   Main PID: 1544 (redis-server)
     Status: "Ready to accept connections"
      Tasks: 5 (limit: 4640)
     Memory: 7.3M
        CPU: 18ms
     CGroup: /system.slice/redis.service
             └─1544 "/usr/bin/redis-server 127.0.0.1:6379"

Dec 06 18:33:07 AvraeRedis systemd[1]: Starting Redis persistent key-value database...
Dec 06 18:33:07 AvraeRedis systemd[1]: Started Redis persistent key-value database.
[rocky@AvraeRedis ~]$ redis-cli ping
PONG
[rocky@AvraeRedis ~]$ sudo systemctl enable redis.service
Created symlink /etc/systemd/system/multi-user.target.wants/redis.service → /usr/lib/systemd/system/redis.service.
```

- Ouverture du port 6379

```bash
[rocky@AvraeRedis ~]$ sudo firewall-cmd --permanent --add-port=6379/tcp
success
[rocky@AvraeRedis ~]$ sudo firewall-cmd --reload
success
```

- On redémarre le service

```bash
[rocky@AvraeRedis ~]$ sudo systemctl restart redis.service
```

Il n'y a pas d'autre config à faire pour redis, le default sufit pour Avrae

**Sur la machine avec Avrae**

Comme pour mongodb, on edit les mêmes fichiers :
REDIS_URL=redis://:redispwd@10.201.1.13:6379/0

- si le bot est en ligne -> `docker compose down`
- on edit l'url de redis dans le docker/env:

```bash
REDIS_URL=redis://redis:6379/0 -> REDIS_URL=redis://:redispwd@10.201.1.13:6379/0
```

- on edit notre docker-compose.yml pour qu'il ressemble à ça :

```bash
version: '3'

services:
  bot:
    image: avrae
    build:
      context: .
      args:
        DBOT_ARGS: test
        ENVIRONMENT: development
    env_file:
      - ./docker/env
    environment:
      DBOT_ARGS: test
      ENVIRONMENT: development
```

- On peut maintenant relancer Avrae avec un nouveau build qui prendra nos modifications en compte.

## 3) Ajout de nextcloud sur chaque machine

L'installation est assez simple, voici son déroulement :

### A - Installation

- Download de netdata :

```bash
[rocky@Avrae ~]$ sudo dnf install epel-release -y
[...]
[rocky@Avrae ~]$ sudo dnf install wget -y
[...]
[rocky@Avrae ~]$ sudo wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh
//yes à chaque demande
[...]
```

- Activation du service

```bash
[rocky@Avrae ~]$ sudo systemctl start netdata
[rocky@Avrae ~]$ sudo systemctl enable netdata
[rocky@Avrae ~]$ sudo systemctl status netdata
● netdata.service - Real time performance monitoring
     Loaded: loaded (/usr/lib/systemd/system/netdata.service; enabled; vendor preset: disabled)
     Active: active (running) since Thu 2022-12-08 23:09:39 CET; 37s ago
   Main PID: 3647 (netdata)
      Tasks: 80 (limit: 4640)
     Memory: 209.6M
        CPU: 5.144s
     CGroup: /system.slice/netdata.service
             ├─3647 /usr/sbin/netdata -P /run/netdata/netdata.pid -D
             ├─3649 /usr/sbin/netdata --special-spawn-server
             ├─3841 bash /usr/libexec/netdata/plugins.d/tc-qos-helper.sh 1
             ├─3842 /usr/libexec/netdata/plugins.d/apps.plugin 1
             ├─3844 /usr/libexec/netdata/plugins.d/ebpf.plugin 1
             └─3845 /usr/libexec/netdata/plugins.d/go.d.plugin 1
```

- Ouverture du port 19999

```bash
[rocky@Avrae ~]$ sudo firewall-cmd --permanent --add-port=19999/tcp
success
[rocky@Avrae ~]$ sudo firewall-cmd --reload
success
```

L'interface de netdate est accesible depuis ce lien :
`http://<Enter Your IP Here>:19999/`

### B - Alertes

Sur votre discord, il va falloir créer et récupérer l'adresse d'un webhook.  

- Rendez-vous dans les paramètres du serveur et dans l'onglet **Intégrations**.  
Ici vous pourrez créer et consulter vos webhooks.  

- Créez-en un avec les infos que vous souhaitez mais récupérer son URL.  

- Une fois fait, sur votre machine, utilisez cette commande :

```bash
sudo /etc/netdata/edit-config health_alarm_notify.conf
```

- et ajoutez à la toute fin, en modifiant l'URL par celle de votre webhook :

```bash
###############################################################################
# sending discord notifications
# note: multiple recipients can be given like this:
#                  "CHANNEL1 CHANNEL2 ..."
# enable/disable sending discord notifications
SEND_DISCORD="YES"
# Create a webhook by following the official documentation -
# https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks
DISCORD_WEBHOOK_URL="https://discordapp.com/api/webhooks/XXXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
# if a role's recipients are not configured, a notification will be send to
# this discord channel (empty = do not send a notification for unconfigured
# roles):
DEFAULT_RECIPIENT_DISCORD="alarms"
```

**Répétez ces opérations par machine à équiper de netdata et vous avez un monitoring d'activé !  
Il est hautement configurable au besoin.**  

## 4) Création de différents scripts

### **A - Script pour démarrer les services au besoin**

**Pour mongodb, redis et netdata**

On change le nom du service cible à chaque fois mais voici la démarche à suivre :  
(mongodb = mongod, redis=redis.service, netdata=netdata)

Exemple pour mongodb :

- Création d'un dossier qui accueillera nos scripts :

```bash
[rocky@AvraeDB ~]$ mkdir script
[rocky@AvraeDB ~]$ cd script/
```

- Création du script :

```bash
[rocky@AvraeDB script]$ sudo vim mongo-on.sh
#!/bin/bash

# Nom du service à vérifier/relancer
SERVICE_NAME="mongod"

# Vérifie si le service est en cours d'exécution
if ! systemctl is-active --quiet $SERVICE_NAME; then
  # Le service n'est pas en cours d'exécution, on le relance
  systemctl start $SERVICE_NAME
fi
```

- On vérifie et adapte les droits + création d'un user dédié

```bash
[rocky@AvraeDB script]$ ls -al
total 4
drwxr-xr-x. 2 rocky rocky  25 Dec  8 11:19 .
drwx------. 6 rocky rocky 172 Dec  8 11:18 ..
-rw-r--r--. 1 root  root  276 Dec  8 11:19 mongo-on.sh
[rocky@AvraeDB script]$ sudo useradd scripter -d /home/rocky/script -s /usr/bin/nologin
[sudo] password for rocky:
useradd: Warning: missing or non-executable shell '/usr/bin/nologin'
useradd: warning: the home directory /home/rocky/script already exists.
useradd: Not copying any file from skel directory into it.
[rocky@AvraeDB script]$ sudo chown scripter mongo-on.sh
[rocky@AvraeDB script]$ sudo chmod +x mongo-on.sh
```

- on crée un service et un timer pour que le script soit éxécuté à intervalle régulier (configurable)

```bash
[rocky@AvraeDB script]$ sudo vim /etc/systemd/system/mongo-on.service
[Unit]
Description=Relance de mongod

[Service]
Type=oneshot
ExecStart=/home/rocky/script/mongo-on.sh

[Install]
WantedBy=multi-user.target

[rocky@AvraeDB script]$ sudo vim /etc/systemd/system/mongo-on.timer
[Unit]
Description=Timer relance mongo

[Service]
Type=oneshot
ExecStart=/home/rocky/script/mongo-on.sh

[Timer]
OnCalendar=hourly

[Install]
WantedBy=multi-user.target
```

- On active ça :

```bash
[rocky@AvraeDB script]$ sudo systemctl daemon-reload
[rocky@AvraeDB script]$ sudo systemctl start mongo-on.timer
[rocky@AvraeDB script]$ sudo systemctl enable mongo-on.timer
Created symlink /etc/systemd/system/multi-user.target.wants/mongo-on.timer → /etc/systemd/system/mongo-on.timer.
[rocky@AvraeDB script]$ sudo systemctl status mongo-on.timer
● mongo-on.timer - Timer relance mongo
     Loaded: loaded (/etc/systemd/system/mongo-on.timer; enabled; vendor preset: disabled)
     Active: active (waiting) since Thu 2022-12-08 11:47:36 CET; 3s ago
      Until: Thu 2022-12-08 11:47:36 CET; 3s ago
    Trigger: Thu 2022-12-08 12:00:00 CET; 12min left
   Triggers: ● mongo-on.service

Dec 08 11:47:36 AvraeDB systemd[1]: Stopped Timer relance mongo.
Dec 08 11:47:36 AvraeDB systemd[1]: Stopping Timer relance mongo...
Dec 08 11:47:36 AvraeDB systemd[1]: Started Timer relance mongo.
```

**Notre script est maintenant lancé plusieurs fois par jour pour vérifier que mongodb est bien démarré sinon il le lance. On fait de même avec les autres services sur leurs machines respectives en suivant les mêmes commandes.**

### **B - Configuration d'une backup mongodb automatique et régulière**

**Sur la machine hébergeant mongodb**

- Création du script et du dossier à dump

```bash
[rocky@AvraeDB ~]$ mkdir mongo-dump 
[rocky@AvraeDB ~]$ cd script/
[rocky@AvraeDB script]$ sudo vim mongo-backup.sh
#!/bin/bash

TODAY=`date +"%d%b%Y"`
MONGO_USER='avraeBot'
MONGO_PASSWD='avraepwd'
DATABASE_NAME='avrae'

echo "Running backup"
cd /home/rocky/mongo-dump
mongodump --authenticationDatabase="admin" -u=${MONGO_USER} -p=${MONGO_PASSWD} -d=${DB_NAME} --out /home/rocky/mongo-dump/${TODAY} --gzip
```

- Gestion des droits

```bash
[rocky@AvraeDB ~]$ sudo chown scripter script/mongo-backup.sh
[rocky@AvraeDB ~]$ sudo chmod +x script/mongo-backup.sh
```

- on crée un service et un timer pour que la backup soit éxécutée à intervalle régulier

```bash
[rocky@AvraeDB]$ sudo vim /etc/systemd/system/mongo-backup.service
[Unit]
Description= Execution backup mongodb

[Service]
Type=oneshot
ExecStart=/home/rocky/script/mongo-backup.sh

[Install]
WantedBy=multi-user.target

[rocky@AvraeDB]$ sudo vim /etc/systemd/system/mongo-backup.timer
[Unit]
Description=Timer relance mongo backup

[Service]
Type=oneshot
ExecStart=/home/rocky/script/mongo-backup.sh

[Timer]
OnCalendar=daily

[Install]
WantedBy=multi-user.target
```

- On active ça :

```bash
[rocky@AvraeDB]$ sudo systemctl daemon-reload
[rocky@AvraeDB]$ sudo systemctl start mongo-backup.timer
[rocky@AvraeDB]$ sudo systemctl enable mongo-backup.timer
Created symlink /etc/systemd/system/multi-user.target.wants/mongo-backup.timer → /etc/systemd/system/mongo-backup.timer.
```

**On peut désormais avoir accès à une dump journalière de la collection de notre mongodb qu'on peut simplement restaurer avec :**

```bash
mongorestore /home/rocky/mongo-dump/X
```

X étant la date de la backup visée.

### **C - Script pour vérifier et garder notre bot allumé (soit notre container)**

On va d'abord s'assurer qu'il n'est pas actuellement en marche et ensuite :

- Bien etre dans le dossier d'Avrae ! (où il y a le Dockerfile)
- Build le container de cette façon :

```bash
docker build . -t avrae
```

- On peut désormais juste le lancer avec :

```bash
docker compose up
```

- et l'éteindre avec :

```bash
docker compose down
```

- Ainsi il utilise nos paramètres particuliers, du docker-compose.yml

On va mettre en place le script bash qui va vérifier si il est lancé et sinon suivre ses commandes pour l'éxécuter.  
On en fera aussi un service avec un timer.

- Création du script

```bash
[rocky@Avrae ~]$ mkdir script
[rocky@Avrae ~]$ cd script/
[rocky@Avrae script]$ sudo vim docker-check.sh
#!/bin/bash

# Change to the directory /home/rocky/avrae or the modify with the path to your docker
cd /home/rocky/avrae

# Check if the Docker container is running
if ! docker ps -q --filter name=my-container
then
  # Start the Docker container if it is not running
  docker start my-container
fi
```

- Gestion des droits

```bash
[rocky@Avrae script]$ sudo useradd scripter -d /home/rocky/script -s /usr/bin/nologin
useradd: Warning: missing or non-executable shell '/usr/bin/nologin'
useradd: warning: the home directory /home/rocky/script already exists.
useradd: Not copying any file from skel directory into it.
[rocky@Avrae script]$ sudo chown scripter docker-check.sh
[rocky@Avrae script]$ sudo chmod +x docker-check.sh
```

- Création et activation de docker-check.service :

```bash
[rocky@Avrae script]$ sudo vim /etc/systemd/system/docker-check.service
[Unit]
Description=docker-check service one shot

[Service]
ExecStart=/bin/bash ./home/rocky/script/docker-check.sh
Type=oneshot

[Install]
WantedBy=multi-user.target                        
```

- Création et activation de docker-check.timer :

```bash
[rocky@Avrae script]$ sudo vim /etc/systemd/system/docker-check.timer
[Unit]
Description=Run docker-check regularly

[Service]
Type=oneshot
ExecStart=/bin/bash ./home/rocky/script/docker-check.sh

[Timer]
OnCalendar=hourly
#toutes les heures
Persistent=true

[Install]
WantedBy=timers.target
```

- Activation

```bash
[rocky@Avrae script]$ sudo systemctl daemon-reload
[rocky@Avrae script]$ sudo systemctl start docker-check.timer
[rocky@Avrae script]$ sudo systemctl enable docker-check.timer
Created symlink /etc/systemd/system/timers.target.wants/docker-check.timer → /etc/systemd/system/docker-check.timer.
[rocky@Avrae script]$ sudo systemctl status docker-check.timer
● docker-check.timer - Run docker-check regularly
     Loaded: loaded (/etc/systemd/system/docker-check.timer; enabled; vendor preset: disabled)
     Active: active (waiting) since Thu 2022-12-08 18:58:17 CET; 13s ago
      Until: Thu 2022-12-08 18:58:17 CET; 13s ago
    Trigger: Thu 2022-12-08 19:00:00 CET; 1min 29s left
   Triggers: ● docker-check.service

Dec 08 18:58:17 Avrae.Bot systemd[1]: Started Run docker-check regularly.
```

**Voilà nous avons un script s'activant à rythme régulier et qui allume le docker avrae au besoin**

# **Fin**
