# TP1 : (re)Familiaration avec un système GNU/Linux

## 0. Préparation de la machine 

On configure le réseau local partagé entre ces machines directement via Virtual Box.  
-> 10.101.1.1/24

Node1 possède l'IP : 10.101.1.11  
Node2 possède l'IP : 10.101.1.12

On les a attribué en créant et en éditant le fichier `/etc/sysconfig/network-scripts/ifcfg-enp0s8` : 

```bash
DEVICE=enp0s8

BOOTPROTO=static
ONBOOT=yes

IPADDR=10.101.1.1X
NETMASK=255.255.255.0
``` 

**Ping de Node2 vers Node1 :**  
```bash
[rocky@localhost ~]$ ping 10.101.1.11
PING 10.101.1.11 (10.101.1.11) 56(84) bytes of data.
64 bytes from 10.101.1.11: icmp_seq=1 ttl=64 time=0.854 ms
64 bytes from 10.101.1.11: icmp_seq=2 ttl=64 time=1.31 ms
^C
--- 10.101.1.11 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 0.854/1.080/1.306/0.226 ms
```

**Changement de nom de chaque machine :**

```bash
sudo hostnamectl set-hostname nodeX.tp1.b2
sudo reboot now
```

**Changement du serveur DNS utilisé :**

On va modifier celui de l'interface NAT (enp0s3) car c'est par là que le DNS va être utilisé.  
On va éditer ce ficher sur chaque machine : `/etc/sysconfig/network-scripts/ifcfg-enp0s3`, avec ces lignes :

```bash
DEVICE=enp0s3
NAME=nat

BOOTPROTO=static
ONBOOT=yes

IPADDR=10.0.2.15
NETMASK=255.255.255.0

DNS1=1.1.1.1
GATEWAY=10.0.2.2
```
Une fois fait on éxécute les commandes suivantes :
```bash
[rocky@node1 ~]$ sudo systemctl restart NetworkManager
[rocky@node1 ~]$ sudo nmcli con show
NAME    UUID                                  TYPE      DEVICE
enp0s3  9e5935c5-5f6c-3471-93c0-84d07391fbe0  ethernet  enp0s3
lan     00cb8299-feb9-55b6-a378-3fdc720e0bc6  ethernet  enp0s8
nat     3c36b8c2-334b-57c7-91b6-4401f3489c69  ethernet  --
[rocky@node1 ~]$ sudo nmcli con up nat
Connection successfully activated (D-Bus active path: /org/freedesktop/NetworkManager/ActiveConnection/3)
[rocky@node1 ~]$ sudo nmcli con show
NAME    UUID                                  TYPE      DEVICE
nat     3c36b8c2-334b-57c7-91b6-4401f3489c69  ethernet  enp0s3
lan     00cb8299-feb9-55b6-a378-3fdc720e0bc6  ethernet  enp0s8
enp0s3  9e5935c5-5f6c-3471-93c0-84d07391fbe0  ethernet  --
```
On peut voir avec le `show` que notre interface "nat" n'était pas directement activé, `up` a permis de changer cela.  
Et on va pouvoir vérifier avec la commande dig que les requêtes DNS se font bien maintenant à 1.1.1.1

```bash
[rocky@node1 ~]$ dig ynov.com
; <<>> DiG 9.16.23-RH <<>> ynov.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 36482
;; flags: qr rd ra; QUERY: 1, ANSWER: 3, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;ynov.com.                      IN      A
```
La partie suivante met en avant la réponse DNS pour ynov.com :  
```bash
;; ANSWER SECTION:
ynov.com.               62      IN      A       104.26.10.233
ynov.com.               62      IN      A       172.67.74.226
ynov.com.               62      IN      A       104.26.11.233
```
Et celle-ci montre que le serveur nous ayant répondu est bien 1.1.1.1 :  
```bash
;; Query time: 24 msec
;; SERVER: 1.1.1.1#53(1.1.1.1)
;; WHEN: Mon Nov 14 12:04:18 CET 2022
;; MSG SIZE  rcvd: 85
```

**Edition du fichier hosts pour pouvoir communiquer avec l'autre machine sans passer par son IP :**

```bash
[rocky@node1 ~]$ sudo vim /etc/hosts
[sudo] password for rocky:
[rocky@node1 ~]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.101.1.12 node2.tp1.
10.101.1.1  host
[rocky@node1 ~]$ ping node2.tp1.b2
PING node2.tp1.b2 (10.101.1.12) 56(84) bytes of data.
64 bytes from node2.tp1.b2 (10.101.1.12): icmp_seq=1 ttl=64 time=1.01 ms
64 bytes from node2.tp1.b2 (10.101.1.12): icmp_seq=2 ttl=64 time=0.691 ms
^C
--- node2.tp1.b2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.691/0.848/1.005/0.157 ms
```

Il en va de même pour Node2 mais on précise l'IP et le nom de Node1 à la place.

**Vérification de la configuration du firewall :**

```bash
[rocky@node1 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: enp0s3 enp0s8
  sources:
  services: cockpit dhcpv6-client ssh
  ports:
  protocols:
  forward: yes
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

Par défaut, le firewall bloque quasiment tout à part quelques exceptions telles que le service ssh comme on peut voir. On en a évidemment besoin mais on pourrait potentiellement interdire aussi les deux autres. Le dhcp étant par exemple inutile étant donné que nous configurons nos ips manuellement.  
Pour ce faire on utiliserait la commande : 
```bash
sudo firewall-cmd --remove-service=dhcpv6-client --permanent
```

## I/ Utilisateurs

### 1. Création et configuration

**Création de l'utilisateur :**  
On utilise la commande :
```bash
sudo useradd toto -m -s /bin/sh -u 2000
```

On peut vérifier sa création et ses infos avec `cat /etc/passwd`:
```bash
[rocky@node1 ~]$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
...
tcpdump:x:72:72::/:/sbin/nologin
toto:x:2000:2000::/home/toto:/bin/sh
```

Toto est bien créé et il possède la bonne configuration.

**Création d'un groupe :**
```bash
sudo groupadd admins
```

On édite avec : 
```bash
[rocky@node1 ~]$ sudo visudo
```
et on ajoute la ligne suivante    `%admins ALL=(ALL)         ALL`

**Ajout de l'utilisateur au groupe :**  

On utilise la commande suivante :
```bash
usermod -aG admins toto
```

Si on veut le tester, il faudra attribuer un mot de passe à l'utilisateur de ce groupe.  
On peut le faire avec `sudo passwd toto`

### 2. SSH

Actuellement on a besoin du mot de passe de toto pour s'y connecter via ssh.
On va remédier à ça en générant (ssh-keygen) et important une clé ssh. (pour le coup j'en ai déjà une, ici on peut la réutiliser mais
autrement il faut toujours en créer une nouvelle pour la sécurité)

On fournit donc notre "cadenas" à la machine (serveur cible), on peut utiliser `ssh-copy-id toto@10.101.1.11` mais malheureusement sur windows on doit le faire à la main.
```bash
sudo mkdir .ssh
cd .ssh/
sudo vim authorized_keys
```
Après on peut se connecter en ssh sans rentrer de mot de passe pour toto.

## II/ Partitionnement

**Utilisation de LVM :**

```bash
[toto@node1 ~]$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda           8:0    0    8G  0 disk
├─sda1        8:1    0    1G  0 part /boot
└─sda2        8:2    0    7G  0 part
  ├─rl-root 253:0    0  6.2G  0 lvm  /
  └─rl-swap 253:1    0  820M  0 lvm  [SWAP]
sdb           8:16   0    3G  0 disk
sdc           8:32   0    3G  0 disk
sr0          11:0    1 1024M  0 rom
sr1          11:1    1 1024M  0 rom
```
On peut voir les deux disques crées -> sdb et sdc.

Ajout en physical volume :
```bash
[toto@node1 ~]$ sudo pvcreate /dev/sdb
[sudo] password for toto:
  Physical volume "/dev/sdb" successfully created.
[toto@node1 ~]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
```

Création d'un volume group avec pour base sdb :
```bash
[toto@node1 ~]$ sudo vgcreate data /dev/sdb
  Volume group "data" successfully created
```

On y ajoute le PV de sdc :
```bash
[toto@node1 ~]$ sudo vgextend data /dev/sdc
  Volume group "data" successfully extended
```

Création des 3 logical volumes de 1 go :
```bash
[toto@node1 ~]$ sudo lvcreate -L 1G data -n data1
  Logical volume "data1" created.
[toto@node1 ~]$ sudo lvcreate -L 1G data -n data2
  Logical volume "data2" created.
[toto@node1 ~]$ sudo lvcreate -L 1G data -n data3
  Logical volume "data3" created.
```

Formatage des partitions : 
```bash
[toto@node1 ~]$ sudo mkfs -t ext4 /dev/data/data1
mke2fs 1.46.5 (30-Dec-2021)
Creating filesystem with 262144 4k blocks and 65536 inodes
Filesystem UUID: d81d30ff-2b1f-4f3c-86d4-c7558905be5d
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (8192 blocks): done
Writing superblocks and filesystem accounting information: done
```

On monte les partitions et on vérifie leur création :
```bash
[toto@node1 ~]$ sudo mkdir /mnt/part1
[toto@node1 ~]$ sudo mkdir /mnt/part2
[toto@node1 ~]$ sudo mkdir /mnt/part3
[toto@node1 ~]$ sudo mount /dev/data/data1 /mnt/part1
[toto@node1 ~]$ sudo mount /dev/data/data2 /mnt/part2
[toto@node1 ~]$ sudo mount /dev/data/data3 /mnt/part3
[toto@node1 ~]$ df -h
Filesystem              Size  Used Avail Use% Mounted on
devtmpfs                462M     0  462M   0% /dev
tmpfs                   481M     0  481M   0% /dev/shm
tmpfs                   193M  3.0M  190M   2% /run
/dev/mapper/rl-root     6.2G  1.2G  5.1G  18% /
/dev/sda1              1014M  210M  805M  21% /boot
tmpfs                    97M     0   97M   0% /run/user/2000
/dev/mapper/data-data1  974M   24K  907M   1% /mnt/part1
/dev/mapper/data-data2  974M   24K  907M   1% /mnt/part2
/dev/mapper/data-data3  974M   24K  907M   1% /mnt/part3
```

Configuration de fstab pour que la partition soit montée automatiquement au démarrage :
```bash
[toto@node1 ~]$ sudo umount /mnt/part1
[toto@node1 ~]$ df -h
Filesystem              Size  Used Avail Use% Mounted on
devtmpfs                462M     0  462M   0% /dev
tmpfs                   481M     0  481M   0% /dev/shm
tmpfs                   193M  3.0M  190M   2% /run
/dev/mapper/rl-root     6.2G  1.2G  5.1G  18% /
/dev/sda1              1014M  210M  805M  21% /boot
tmpfs                    97M     0   97M   0% /run/user/2000
/dev/mapper/data-data2  974M   24K  907M   1% /mnt/part2
/dev/mapper/data-data3  974M   24K  907M   1% /mnt/part3
[toto@node1 ~]$ sudo vim /etc/fstab
```
On y ajoute `/dev/data/data1 /mnt/part1 ext4 defaults 0 0`
```bash
[toto@node1 ~]$ sudo mount -av
/                        : ignored
/boot                    : already mounted
none                     : ignored
mount: /mnt/part1 does not contain SELinux labels.
       You just mounted a file system that supports labels which does not
       contain labels, onto an SELinux box. It is likely that confined
       applications will generate AVC messages and not be allowed access to
       this file system.  For more details see restorecon(8) and mount(8).
/mnt/part1               : successfully mounted
[toto@node1 ~]$ df -h
Filesystem              Size  Used Avail Use% Mounted on
devtmpfs                462M     0  462M   0% /dev
tmpfs                   481M     0  481M   0% /dev/shm
tmpfs                   193M  3.0M  190M   2% /run
/dev/mapper/rl-root     6.2G  1.2G  5.1G  18% /
/dev/sda1              1014M  210M  805M  21% /boot
tmpfs                    97M     0   97M   0% /run/user/2000
/dev/mapper/data-data2  974M   24K  907M   1% /mnt/part2
/dev/mapper/data-data3  974M   24K  907M   1% /mnt/part3
/dev/mapper/data-data1  974M   24K  907M   1% /mnt/part1
```

## III/ Gestion des services 

### 1. Interaction avec un service existant

S'assurer que le service firewalld est actif et lancé au démarrage:
```bash
[toto@node1 ~]$ sudo systemctl is-active firewalld
active
[toto@node1 ~]$ sudo systemctl is-enabled firewalld
enabled
```

### 2. Création de service
#### A. Unité simpliste

Mise en place :
```bash
[toto@node1 ~]$ cd /etc/systemd/system
[toto@node1 system]$ sudo vim web.service
[toto@node1 system]$ sudo firewall-cmd --add-port=8888/tcp --permanent
success
[toto@node1 system]$ sudo firewall-cmd --reload
success
[toto@node1 system]$ sudo systemctl daemon-reload
[toto@node1 system]$ sudo systemctl status web
○ web.service - Very simple web service
     Loaded: loaded (/etc/systemd/system/web.service; disabled; vendor preset: disabled)
     Active: inactive (dead)
[toto@node1 system]$ sudo systemctl start web
[toto@node1 system]$ sudo systemctl enable web
Created symlink /etc/systemd/system/multi-user.target.wants/web.service → /etc/systemd/system/web.service.
[toto@node1 system]$ sudo systemctl status web
● web.service - Very simple web service
     Loaded: loaded (/etc/systemd/system/web.service; enabled; vendor preset: disabled)
     Active: active (running) since Tue 2022-11-15 01:03:16 CET; 9s ago
   Main PID: 1161 (python3)
      Tasks: 1 (limit: 5908)
     Memory: 9.3M
        CPU: 61ms
     CGroup: /system.slice/web.service
             └─1161 /usr/bin/python3 -m http.server 8888

Nov 15 01:03:16 node1.tp1.b2 systemd[1]: Started Very simple web service.
```

Le service semble accessible depuis le web, et depuis l'autre machine avec un curl :
```bash
[rocky@node2 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="afs/">afs/</a></li>
<li><a href="bin/">bin@</a></li>
<li><a href="boot/">boot/</a></li>
<li><a href="dev/">dev/</a></li>
<li><a href="etc/">etc/</a></li>
<li><a href="home/">home/</a></li>
<li><a href="lib/">lib@</a></li>
<li><a href="lib64/">lib64@</a></li>
<li><a href="media/">media/</a></li>
<li><a href="mnt/">mnt/</a></li>
<li><a href="opt/">opt/</a></li>
<li><a href="proc/">proc/</a></li>
<li><a href="root/">root/</a></li>
<li><a href="run/">run/</a></li>
<li><a href="sbin/">sbin@</a></li>
<li><a href="srv/">srv/</a></li>
<li><a href="sys/">sys/</a></li>
<li><a href="tmp/">tmp/</a></li>
<li><a href="usr/">usr/</a></li>
<li><a href="var/">var/</a></li>
</ul>
<hr>
</body>
</html>
```

#### B. Modification de l'unité

**Préparation de l'environnement :**
```bash
[toto@node1 ~]$ sudo useradd web -m -s /bin/sh -u 3000
[toto@node1 meow]$ ls -al oui
-rw-r--r--. 1 root root 0 Nov 15 01:10 oui
[toto@node1 www]$ sudo chown web ./meow
[toto@node1 meow]$ sudo chown web oui
[toto@node1 www]$ ls -all meow/
total 0
drwxr-xr-x. 2 web  root 17 Nov 15 01:10 .
drwxr-xr-x. 3 root root 18 Nov 15 01:10 ..
-rw-r--r--. 1 web  root  0 Nov 15 01:10 oui
```

**Modification de l'unité de web service :**  

On ajoute les deux lignes suivantes au fichier webservice :
```bash
User=web
WorkingDirectory=/var/www/meow/
```

Il faut penser à redémarrer le service :
```bash
[toto@node1 www]$ sudo systemctl stop web
Warning: The unit file, source configuration file or drop-ins of web.service changed on disk. Run 'systemctl daemon-reload' to reload units.
[toto@node1 www]$ sudo systemctl daemon-reload
[toto@node1 www]$ sudo systemctl start web
[toto@node1 www]$ sudo systemctl status web
● web.service - Very simple web service
     Loaded: loaded (/etc/systemd/system/web.service; enabled; vendor preset: disabled)
     Active: active (running) since Tue 2022-11-15 02:00:12 CET; 8s ago
   Main PID: 1538 (python3)
      Tasks: 1 (limit: 5908)
     Memory: 9.0M
        CPU: 140ms
     CGroup: /system.slice/web.service
             └─1538 /usr/bin/python3 -m http.server 8888

Nov 15 02:00:12 node1.tp1.b2 systemd[1]: Started Very simple web service.
```

Vérification avec curl depuis l'autre machine :
```bash
[rocky@node2 ~]$ curl 10.101.1.11:8888
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Directory listing for /</title>
</head>
<body>
<h1>Directory listing for /</h1>
<hr>
<ul>
<li><a href="oui">oui</a></li>
</ul>
<hr>
</body>
</html>
```

On constate qu'on se situe bien dans le dossier 'meow'.