# Module 3 : Sauvegarde de base de données

## 1/ Script dump et Clean It

**Création de l'utilisateur :**

```bash
CREATE USER 'dump'@'localhost' IDENTIFIED BY '123';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'dump'@'localhost';
FLUSH PRIVILEGES;
```

**Création du script :**

```bash
sudo vim /srv/tp3_db_dump.sh
```
On y inscrit : 
```bash
#!/bin/bash
# Script écrit le 22/11/2022
# Aymeric MOISKA
# Permet de réaliser une backup de la base de donnée nextcloud à intervalle régulier

DATE=`date +"%Y%m%d%H%M%S"`
user="dump"
passwd="123"
namebd="nextcloud"
ipbd=127.0.0.1
backupfile=db_${namebd}_${DATE}

mysqldump --opt --protocol=TCP --user=${user} --password=${passwd} --host=${ipdb} ${namebd} > /srv/db_dumps/${backupfile}.sql

echo "${backupfile} was created"
ls /srv/db_dumps/

gzip /srv/db_dumps/$backupfile.sql

echo "${backupfile}.sql was compressed into ${backupfile}.gz"
ls /srv/db_dumps/
```

Puis :
```bash
[rocky@db ~]$ sudo mkdir /srv/db_dumps/
[rocky@db ~]$ sudo useradd db_dumps -d /srv/db_dumps/ -s /usr/bin/nologin
useradd: Warning: missing or non-executable shell '/usr/bin/nologin'
useradd: warning: the home directory /srv/db_dumps/ already exists.
useradd: Not copying any file from skel directory into it.
[rocky@db ~]$ sudo chown db_dumps /srv/db_dumps/
[rocky@db ~]$ sudo chown db_dumps /srv/tp3_db_dump.sh
[rocky@db ~]$ sudo chmod +x /srv/tp3_db_dump.sh
[rocky@db ~]$ sudo -u db_dumps /srv/tp3_db_dump.sh
```   

## 2/ Service et timer

Création et activation de db-dump.service :
```bash
sudo vim /etc/systemd/system/db-dump-service
[Unit]
Description=BD Dump service one shot

[Service]
ExecStart=/bin/bash ./srv/tp3_db_dump.sh
Type=oneshot

[Install]
WantedBy=multi-user.target
~                            
```
```bash
sudo systemctl status db-dump
sudo systemctl start db-dump
```

Création et activation de db-dump.timer :
```bash
sudo vim /etc/systemd/system/db-dump-service
[Unit]
Description=Run dm-dump regularly

[Timer]
OnCalendar=*-*-* 12:00:00
#tout les jours à 12am
Persistent=true

[Install]
WantedBy=timers.target
```
```bash
[rocky@db srv]$ sudo systemctl start db-dump.timer
[rocky@db srv]$ sudo systemctl enable db-dump.timer
Created symlink /etc/systemd/system/timers.target.wants/db-dump.timer → /etc/systemd/system/db-dump.timer.
[rocky@db srv]$ sudo systemctl status db-dump.timer
● db-dump.timer - Run dm-dump regularly
     Loaded: loaded (/etc/systemd/system/db-dump.timer; enabled; vendor preset: disabled)
     Active: active (waiting) since Sat 2022-11-19 10:56:54 CET; 30s ago
      Until: Sat 2022-11-19 10:56:54 CET; 30s ago
    Trigger: Sat 2022-11-19 12:00:00 CET; 1h 2min left
   Triggers: ● db-dump.service

Nov 19 10:56:54 db.tp2.linux systemd[1]: Started Run dm-dump regularly.
[rocky@db srv]$ sudo systemctl list-timers
NEXT                        LEFT          LAST                        PASSED       UNIT              >
Sat 2022-11-19 12:00:00 CET 1h 2min left  n/a                         n/a          db-dump.timer     >
Sat 2022-11-19 12:20:33 CET 1h 23min left Sat 2022-11-19 10:54:22 CET 3min 10s ago dnf-makecache.time>
Sat 2022-11-19 12:29:01 CET 1h 31min left Fri 2022-11-18 12:29:01 CET 22h ago      systemd-tmpfiles-c>
Sun 2022-11-20 00:00:00 CET 13h left      Sat 2022-11-19 00:00:01 CET 10h ago      logrotate.timer   >

4 timers listed.
Pass --all to see loaded but inactive timers, too
```


Restorer le zip sql file :
```bash
gunzip < [backupfile.sql.gz] | mysql -h localhost -u dump -p 123 nextcloud
```

