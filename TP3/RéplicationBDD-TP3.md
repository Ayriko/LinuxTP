# Module 2 : Réplication de base de données

## 1/ Mise en place d'une nouvelle machine Rocky Linux Slave (nommée ici db2_rep.tp3.linux)  
Dans le même réseau hôte que le serveur web et la première db.  
IP -> 10.102.1.13  
edit ifcfg-enp0s8  
reload NetworkManager  
changement hostname -> sudo hostnamectl set-hostname  
reboot  
Echange clé ssh  
dnf update  
désactiver selinux  

## 2/ Configuration de mariaDB sur la machine Master (déjà existante)

**Activation des logs pour la réplication**  
`sudo vim /etc/my.cnf.d/mariadb-server.cnf`  
-> uncomment bind-adress (vérifier que c'est bien 0.0.0.0)  
-> ajouter à la fin :  
```bash
server_id=1
log-bin=/var/log/mariadb/mariadb-bin.log
max_binlog_size=100M
relay_log = /var/log/mariadb/mariadb-relay-bin
relay_log_index = /var/log/mariadb/mariadb-relay-bin.index
```

**Création d'un utilisateur dédié dans la db**
```bash
mysql -u root -p
CREATE USER 'replication'@'10.102.1.13' identified by 'rep';
GRANT REPLICATION SLAVE ON *.* TO 'replication'@'10.102.1.13';
FLUSH PRIVILEGES;
```

## 4/ Mise en place de la réplication

**Sur le Master**
```bash
FLUSH PRIVILEGES WITH READ LOCK;
SHOW MASTER STATUS;
``` 
Garder de côté les infos Log_File et Log_Pos ! Il faudra les utiliser plus tard ! 
Il ne faut pas fermer cette session mysql, ouvrir un second terminal connecté à cette machine ou faire la suite depuis cette dernière :  
```bash
sudo mysqldump -u root -p nextcloud > nextcloudDUMP.sql
sudo scp nextcloudDUMP.sql rocky@10.102.1.13:/home/rocky/
```

**Sur le slave**

Première étape :   
! Bien penser à rentrer un nouveau mdp pour root lors de mysql_secure_installation !  
```bash
sudo dnf install mariadb-server -y
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation
sudo firewall-cmd --add-port=3306/tcp --permanent
sudo firewall-cmd --reload
```
Seconde étape :  
```bash
mysql -u root -p
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EXIT;
```
Troisième étape :
```bash
sudo mysql -u root -p nextcloud < nextcloudDUMP.sql
sudo vim /etc/my.cnf.d/mariadb-server.cnf
-> uncomment bind-adress (vérifier que égal à 0.0.0.0)
-> ajouter à la fin :
server-id              = 2
log_bin                = /var/log/mariadb/mariadb-bin.log
max_binlog_size        = 100M
relay_log = /var/log/mariadb/mariadb-relay-bin
relay_log_index = /var/log/mariadb/mariadb-relay-bin.index
```
Quatrième étape :  
On va utiliser ici les infos récupérées sur le master !  
```bash
mysql -u root -p
STOP SLAVE;
CHANGE MASTER TO MASTER_HOST = '10.102.1.12', MASTER_USER = 'replication', MASTER_PA
SSWORD = 'rep', MASTER_LOG_FILE = 'xxx', MASTER_LOG_POS = X;
START SLAVE;
```

**Dernier retour sur le master**
```bash
UNLOCK TABLES;
```

**La réplication est désormais active**

On peut vérifier avec `SELECT * FROM oc_filecache;` par exemple. Si on ajoute des images sur nextcloud on pourra les y retrouver.
