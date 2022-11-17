# TP2 : Gestion de service

## I/ Un premier serveur web

### 1. Installation

**Installation du serveur Apache**

```bash
sudo dnf install -y httpd
```

**Démarrer le service Apache**

```bash
[rocky@web ~]$ sudo systemctl start httpd
[sudo] password for rocky:
[rocky@web ~]$ sudo systemctl enable httpd
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
[rocky@web ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
```

**Test**

 Vérification que le service est démarré :
 ```bash
[rocky@web ~]$ sudo systemctl is-active httpd
active
```

Vérification que le service se lance automatiquement :
```bash
[rocky@web ~]$ sudo systemctl is-enabled httpd
enabled
```

Vérification que l'on peut joindre le service localement :
```bash
[rocky@web ~]$ curl localhost
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/

      html {
```

Vérification depuis notre machine :

```bash
PS C:\Users\aymer> curl 10.102.1.11:80
curl : HTTP Server Test Page
This page is used to test the proper operation of an HTTP server after it has been installed on a Rocky Linux system.
If you can read this page, it means that the software it working correctly.
Just visiting?
This website you are visiting is either experiencing problems or could be going through maintenance.
If you would like the let the administrators of this website know that you've seen this page instead of the page
you've expected, you should send them an email. In general, mail sent to the name "webmaster" and directed to the
website's domain should reach the appropriate person.
The most common email address to send to is: "webmaster@example.com"
```

### 2. Avancer vers la maîtrise du service 

**Le service Apache**

```bash
[rocky@web ~]$ sudo systemctl cat httpd.service
# /usr/lib/systemd/system/httpd.service
# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# /usr/lib/systemd/system/httpd.service
# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# /usr/lib/systemd/system/httpd.service
# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# behaviour, run "systemctl edit httpd" to create an override unit.

# For example, to pass additional options (such as -D definitions) to
# the httpd binary at startup, create an override unit (as is done by
# systemctl edit) and enter the following:

#       [Service]
#       Environment=OPTIONS=-DMY_DEFINE

[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true
OOMPolicy=continue

[Install]
WantedBy=multi-user.target
```

**Déterminer sous quel utilisateur tourne le processus Apache**  

Mise en évide de l'utilisateur utilisé :

```bash
[rocky@web ~]$ sudo cat /etc/httpd/conf/httpd.conf

ServerRoot "/etc/httpd"

Listen 80

Include conf.modules.d/*.conf

User apache
Group apache


ServerAdmin root@localhost
```

On vérifie les processus en cours pour confirmer qu'apache est bien l'utilisateur derrière le processus :

```bash
[rocky@web ~]$ ps -ef
apache       711     686  0 10:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache       713     686  0 10:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache       714     686  0 10:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache       716     686  0 10:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
```

On vérifie les droits de l'user apache sur le fichier.

```bash
[rocky@web testpage]$ ls -al
total 12
drwxr-xr-x.  2 root root   24 Nov 15 10:16 .
drwxr-xr-x. 82 root root 4096 Nov 15 10:16 ..
-rw-r--r--.  1 root root 7620 Jul  6 04:37 index.html
```

On observe que Apache donne en priorité les droits d'user à root, ainsi le user apache possède seulement les droits de lecture sur le fichier.

**Changer l'utilisateur utilisé par Apache**

On crée un nouvel utilisateur en se basant sur le user apache.
Infos avec `cat /etc/passwd`

```bash
[rocky@web ~]$ sudo useradd toto -d /usr/share/httpd -s /sbin/nologin -u 4000
useradd: warning: the home directory /usr/share/httpd already exists.
useradd: Not copying any file from skel directory into it.
Creating mailbox file: File exists
```

On modifie le ficher `/etc/httpd/conf/httpd.conf` en modifiant "user apache" par "user toto"
et on vérifie avec un ps -ef.

```bash
toto        1264    1263  0 11:50 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
toto        1265    1263  0 11:50 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
toto        1266    1263  0 11:50 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
toto        1267    1263  0 11:50 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
```

**Faites en sorte que Apache tourne sur un autre port**

Aussi dans le fichier httpd.conf, on peut modifier la ligne "listen 80" par "listen 8080" par exemple. 
On ouvre ce nouveau port dans le firewall et on ferme l'autre :  
```bash
[rocky@web ~]$ sudo vim /etc/httpd/conf/httpd.conf
[rocky@web ~]$ sudo firewall-cmd --add-port=8080/tcp --permanent
success
[rocky@web ~]$ sudo firewall-cmd --remove-port=80/tcp --permanent
success
[rocky@web ~]$ sudo firewall-cmd --reload
success
[rocky@web ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client ssh
  ports: 8080/tcp
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

On redémarre le service et on vérifie qu'il soit toujours accessible :

```bash
[rocky@web ~]$ sudo systemctl stop httpd
[rocky@web ~]$ sudo systemctl start httpd
[rocky@web ~]$ curl localhost:8080
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/

      html {
        height: 100%;
        width: 100%;
      }
```

Curl depuis notre machine :
```bash
PS C:\Users\aymer> curl 10.102.1.11:8080
curl : HTTP Server Test Page
This page is used to test the proper operation of an HTTP server after it has been installed on a
Rocky Linux system. If you can read this page, it means that the software it working correctly.
Just visiting?
This website you are visiting is either experiencing problems or could be going through maintenance.
If you would like the let the administrators of this website know that you've seen this page instead
of the page you've expected, you should send them an email. In general, mail sent to the name
"webmaster" and directed to the website's domain should reach the appropriate person.
The most common email address to send to is: "webmaster@example.com"`
```

## II/ Une stack web plus avancée   

### A. Base de données

**Installation de MariaDB**

```bash
[rocky@db ~]$ sudo dnf install -y mariadb-server
[rocky@db ~]$ sudo systemctl enable mariadb
Created symlink /etc/systemd/system/mysql.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/mysqld.service → /usr/lib/systemd/system/mariadb.service.
Created symlink /etc/systemd/system/multi-user.target.wants/mariadb.service → /usr/lib/systemd/system/mariadb.service.
[rocky@db ~]$ sudo systemctl start mariadb
[rocky@db ~]$ sudo mysql_secure_installation

NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
      SERVERS IN PRODUCTION USE!  PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
haven't set the root password yet, you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password or using the unix_socket ensures that nobody
can log into the MariaDB root user without the proper authorisation.

You already have your root account protected, so you can safely answer 'n'.

Switch to unix_socket authentication [Y/n] n
 ... skipping.

You already have your root account protected, so you can safely answer 'n'.

Change the root password? [Y/n] y
 New password:
 Re-enter new password:
 Password updated successfully!
 Reloading privilege tables..
  ... Success!

By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them.  This is intended only for testing, and to make the installation
go a bit smoother.  You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] Y
 ... Success!

Normally, root should only be allowed to connect from 'localhost'.  This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] n
 ... Skipping.

By default, MariaDB comes with a database named 'test' that anyone can
access.  This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
 - Dropping test database...
 ... Success!
 - Removing privileges on test database...
 ... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
 ... Success!

Cleaning up...

All done!  If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

Vérification avec ss :
```bash
[rocky@db ~]$ sudo ss -nltp
[sudo] password for rocky:
State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port Process
LISTEN  0       128            0.0.0.0:22          0.0.0.0:*     users:(("sshd",pid=689,fd=3))
LISTEN  0       80                   *:3306              *:*     users:(("mariadbd",pid=34828,fd=19))
LISTEN  0       128               [::]:22             [::]:*     users:(("sshd",pid=689,fd=4))
```

Le port utilisé par mariadb est donc le 3306.
On va pouvoir l'autoriser dans le firewall.
```bash
[rocky@db ~]$ sudo firewall-cmd --add-port=3306/tcp --permanent
success
[rocky@db ~]$ sudo firewall-cmd --reload
success
```

**Préparation de la base pour NextCloud**
 
```bash
[rocky@db ~]$ sudo mysql -u root -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 10
Server version: 10.5.16-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE USER 'nextcloud'@'10.102.1.11' IDENTIFIED BY 'pewpewpew';
Query OK, 0 rows affected (0.035 sec)

MariaDB [(none)]> CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.102.1.11';
Query OK, 0 rows affected (0.036 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```

**Exploration de base de donnée**

```bash
[rocky@web ~]$ mysql -u nextcloud -h 10.102.1.12 -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 14
Server version: 5.5.5-10.5.16-MariaDB MariaDB Server

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.00 sec)

mysql> USE nextcloud;
Database changed
mysql> SHOW TABLES;
Empty set (0.00 sec)
```

**Trouver une commande SQL pour lister tous les utilisateurs de la base de données**

(en étant connecté en root sur la db, nextcloud ne possède pas les droits pour la suite)

```bash
SELECT * FROM mysql.user;
MariaDB [(none)]> SELECT * FROM mysql.user;
+-------------+-------------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
| Host        | User        | Password                                  | Select_priv | Insert_priv | Update_priv | Delete_priv | Create_priv | Drop_priv | Reload_priv | Shutdown_priv | Process_priv | File_priv | Grant_priv | References_priv | Index_priv | Alter_priv | Show_db_priv | Super_priv | Create_tmp_table_priv | Lock_tables_priv | Execute_priv | Repl_slave_priv | Repl_client_priv | Create_view_priv | Show_view_priv | Create_routine_priv | Alter_routine_priv | Create_user_priv | Event_priv | Trigger_priv | Create_tablespace_priv | Delete_history_priv | ssl_type | ssl_cipher | x509_issuer | x509_subject | max_questions | max_updates | max_connections | max_user_connections | plugin                | authentication_string                     | password_expired | is_role | default_role | max_statement_time |
+-------------+-------------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
| localhost   | mariadb.sys |                                           | N           | N           | N           | N           | N           | N         | N           | N             | N            | N         | N          | N               | N          | N          | N            | N          | N                     | N                | N            | N               | N                | N
  | N              | N                   | N                  | N                | N          | N            | N                      | N                   |          |            |             |
     |             0 |           0 |               0 |                    0 | mysql_native_password |                                           | Y                | N       |              |           0.000000 |
| localhost   | root        | *81F5E21E35407D884A6CD4A731AEBFB6AF209E1B | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y
  | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |
     |             0 |           0 |               0 |                    0 | mysql_native_password | *81F5E21E35407D884A6CD4A731AEBFB6AF209E1B | N                | N       |              |           0.000000 |
| localhost   | mysql       | invalid                                   | Y           | Y           | Y           | Y           | Y           | Y         | Y           | Y             | Y            | Y         | Y          | Y               | Y          | Y          | Y            | Y          | Y                     | Y                | Y            | Y               | Y                | Y
  | Y              | Y                   | Y                  | Y                | Y          | Y            | Y                      | Y                   |          |            |             |
     |             0 |           0 |               0 |                    0 | mysql_native_password | invalid                                   | N                | N       |              |           0.000000 |
| 10.102.1.11 | nextcloud   | *AF136CF35F0D546F69717A7F18C18849666E64D0 | N           | N           | N           | N           | N           | N         | N           | N             | N            | N         | N          | N               | N          | N          | N            | N          | N                     | N                | N            | N               | N                | N
  | N              | N                   | N                  | N                | N          | N            | N                      | N                   |          |            |             |
     |             0 |           0 |               0 |                    0 | mysql_native_password | *AF136CF35F0D546F69717A7F18C18849666E64D0 | N                | N       |              |           0.000000 |
+-------------+-------------+-------------------------------------------+-------------+-------------+-------------+-------------+-------------+-----------+-------------+---------------+--------------+-----------+------------+-----------------+------------+------------+--------------+------------+-----------------------+------------------+--------------+-----------------+------------------+------------------+----------------+---------------------+--------------------+------------------+------------+--------------+------------------------+---------------------+----------+------------+-------------+--------------+---------------+-------------+-----------------+----------------------+-----------------------+-------------------------------------------+------------------+---------+--------------+--------------------+
4 rows in set (0.002 sec)
```

### B. Serveur Web et NextCloud

**Install de php**

```bash
[rocky@web ~]$ sudo dnf config-manager --set-enabled crb
[rocky@web ~]$ sudo dnf install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm -y
[rocky@web ~]$ dnf module list php
[rocky@web ~]$ sudo dnf module enable php:remi-8.1 -y
[rocky@web ~]$ sudo dnf install -y php81-php
[rocky@web ~]$ sudo dnf install -y libxml2 openssl php81-php php81-php-ctype php81-php-curl php81-php-gd php81-php-iconv php81-php-json php81-php-libxml php81-php-mbstring php81-php-openssl php81-php-posix php81-php-session php81-php-xml php81-php-zip php81-php-zlib php81-php-pdo php81-php-mysqlnd php81-php-intl php81-php-bcmath php81-php-gmp --nogpgcheck
```

**Récupérer nextcloud**

On installe d'abord wget et un unzip :
```bash
[rocky@web ~]$ sudo dnf install wget -y
[rocky@web ~]$ sudo dnf install unzip -y
```

Puis on récupère le fichier compressé pour ensuite la manipuler:
```bash
[rocky@web ~]$ sudo wget https://download.nextcloud.com/server/prereleases/nextcloud-25.0.0rc3.zip
[rocky@web ~]$ sudo unzip nextcloud-25.0.0rc3.zip
[rocky@web ~]$ sudo cp -r nextcloud /var/www/tp2_nextcloud 
```

On vérifie que tout c'est bien passé :
```bash
[rocky@web ~]$ cat /var/www/tp2_nextcloud/index.html
<!DOCTYPE html>
<html>
<head>
        <script> window.location.href="index.php"; </script>
        <meta http-equiv="refresh" content="0; URL=index.php">
</head>
</html>
```

On attribue le fichier à l'utilisateur apache :
```bash
[rocky@web ~]$ sudo chown -R apache /var/www/tp2_nextcloud/
[rocky@web ~]$ ls -all /var/www/tp2_nextcloud/
total 140
drwxr-xr-x. 14 apache root  4096 Nov 15 17:13 .
drwxr-xr-x.  5 root   root    54 Nov 15 17:13 ..
drwxr-xr-x. 47 apache root  4096 Nov 15 17:13 3rdparty
drwxr-xr-x. 50 apache root  4096 Nov 15 17:13 apps
-rw-r--r--.  1 apache root 19327 Nov 15 17:13 AUTHORS
drwxr-xr-x.  2 apache root    67 Nov 15 17:13 config
-rw-r--r--.  1 apache root  4095 Nov 15 17:13 console.php
-rw-r--r--.  1 apache root 34520 Nov 15 17:13 COPYING
drwxr-xr-x. 23 apache root  4096 Nov 15 17:13 core
-rw-r--r--.  1 apache root  6317 Nov 15 17:13 cron.php
drwxr-xr-x.  2 apache root  8192 Nov 15 17:13 dist
-rw-r--r--.  1 apache root  3253 Nov 15 17:13 .htaccess
-rw-r--r--.  1 apache root   156 Nov 15 17:13 index.html
-rw-r--r--.  1 apache root  3456 Nov 15 17:13 index.php
drwxr-xr-x.  6 apache root   125 Nov 15 17:13 lib
-rw-r--r--.  1 apache root   283 Nov 15 17:13 occ
drwxr-xr-x.  2 apache root    23 Nov 15 17:13 ocm-provider
drwxr-xr-x.  2 apache root    55 Nov 15 17:13 ocs
drwxr-xr-x.  2 apache root    23 Nov 15 17:13 ocs-provider
-rw-r--r--.  1 apache root  3139 Nov 15 17:13 public.php
-rw-r--r--.  1 apache root  5426 Nov 15 17:13 remote.php
drwxr-xr-x.  4 apache root   133 Nov 15 17:13 resources
-rw-r--r--.  1 apache root    26 Nov 15 17:13 robots.txt
-rw-r--r--.  1 apache root  2452 Nov 15 17:13 status.php
drwxr-xr-x.  3 apache root    35 Nov 15 17:13 themes
drwxr-xr-x.  2 apache root    43 Nov 15 17:13 updater
-rw-r--r--.  1 apache root   101 Nov 15 17:13 .user.ini
-rw-r--r--.  1 apache root   387 Nov 15 17:13 version.php
```

**Adapter la configuration d'Apache**

On vérifie que le fichier de conf principal d'apache inclue bien d'autre sous-fichiers de conf :
```bash
[rocky@web ~]$ sudo cat /etc/httpd/conf/httpd.conf

ServerRoot "/etc/httpd"
[...]
IncludeOptional conf.d/*.conf
```

On crée notre fichier .conf :
```bash
[rocky@web ~]$ sudo vim /etc/httpd/conf.d/nextcloud.conf
<VirtualHost *:80>
  # on indique le chemin de notre webroot
  DocumentRoot /var/www/tp2_nextcloud/
  # on précise le nom que saisissent les clients pour accéder au service
  ServerName  web.tp2.linux

  # on définit des règles d'accès sur notre webroot
  <Directory /var/www/tp2_nextcloud/> 
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>
</VirtualHost>
[rocky@web ~]$ sudo systemctl stop httpd
[rocky@web ~]$ sudo systemctl start httpd
```

### C. Finaliser l'installation de nextcloud

On ajoute la ligne suivante à notre fichier hosts (C:\Windows\System32\drivers\etc\hosts):
`10.102.1.11 web.tp2.linux`

**Exploration de la bdd**

```bash
MariaDB [(none)]> USE nextcloud;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [nextcloud]> SHOW TABLES;
+-----------------------------+
| Tables_in_nextcloud         |
+-----------------------------+
| oc_accounts                 |
| oc_accounts_data            |
| oc_activity                 |
| oc_activity_mq              |
[...]
| oc_vcategory                |
| oc_vcategory_to_object      |
| oc_webauthn                 |
| oc_whats_new                |
+-----------------------------+
95 rows in set (0.001 sec)
```

On peut voir à la fin du `show tables` que l'installation a généré 95 tables dans la base de données NextCloud.