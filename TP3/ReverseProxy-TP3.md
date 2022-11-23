# Module 1 : Reverse Proxy

## Mise en place d'une nouvelle machine Rocky Linux Proxy (nommée ici proxy.tp3.linux)
  
Dans le même réseau hôte que le serveur web.   
Checklist :  
    - IP -> 10.102.1.14  -> edit ifcfg-enp0s8  
    - reload NetworkManager  
    - Changement hostname -> sudo hostnamectl set-hostname  
    - Reboot  
    - Echange clé ssh  
    - dnf update  
    - désactiver selinux  
## 1/ Installation et configuration de nginx

On commence par installer nginx et l'activer.  
```bash
sudo dnf install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```
On identifie le port utilisé et on l'autorise à travers le firewall.
```bash
sudo ss -alnpt
//récupérer le port utilisé par nginx
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```

On vérifie l'utilisateur tournant nginx et si ça fonctionne.
```bash
sudo ps -eg
```
Vous verrez 2 lignes avec nginx dont 1 avec un utilisateur root et l'autre avec un utilisateur nginx.  
Se connecter à `10.102.1.14:80`, si il y a un logo Nginx c'est que tout est ok.

Infos sur les fichiers de conf nginx
```bash
    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
```

```bash
sudo vim /etc/nginx/conf.d/nginx.conf
```
On y inscrit :
```bash
server {
    # On indique le nom que client va saisir pour accéder au service
    # Pas d'erreur ici, c'est bien le nom de web, et pas de proxy qu'on veut ici !
    server_name web.tp2.linux;

    # Port d'écoute de NGINX
    listen 80;

    location / {
        # On définit des headers HTTP pour que le proxying se passe bien
        proxy_set_header  Host $host;
        proxy_set_header  X-Real-IP $remote_addr;
        proxy_set_header  X-Forwarded-Proto https;
        proxy_set_header  X-Forwarded-Host $remote_addr;
        proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;

        # On définit la cible du proxying
        proxy_pass http://web.tp2.linux:80;
    }

    # Deux sections location recommandés par la doc NextCloud
    location /.well-known/carddav {
      return 301 $scheme://$host/remote.php/dav;
    }

    location /.well-known/caldav {
      return 301 $scheme://$host/remote.php/dav;
    }
}
```
Et on redémarre nginx -> `sudo systemctl restart nginx`

! Attention, la suite se fait sur la machine hébergeant le serveur web !
```bash
sudo vim /var/www/tp2_nextcloud/config/config.php
```
On ajoute à la fin :
```
'trusted_proxies' => '10.102.1.14',
```
Et il faut restart le service -> `sudo systemctl restart httpd`

## 2/ Modification du fichier hosts

! Sur le proxy !
On ajoute/modifie la ligne suivante à notre fichier hosts (/etc/hosts):
`10.102.1.11 web.tp2.linux`

! Sur NOTRE PC !
On ajoute/modifie la ligne suivante à notre fichier hosts (C:\Windows\System32\drivers\etc\hosts):
`10.102.1.14 web.tp2.linux`

On peut désormais se connecter au site via ce nom de domaine (uniquement)

## 3/ Obtenir le HTTPS

Génération des 2 clés dans le proxy :  
! attention, lorsqu'il demande un nom de domaine, donnez : web.tp2.linux !  
```bash
 openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout proxykeys/privateKey.key -out proxykeys/certificate.crt
 ```

Dans le fichier /etc/nginx/nginx.conf, on retire/comment :
```bash
server {
    listen       80;
    listen       [::]:80;
    server_name  _;
    root         /usr/share/nginx/html;
    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;

    error_page 404 /404.html;
    location = /404.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }
}   
```

On edit le fichier /etc/nginx/conf.d/proxy.conf
```bash
listen 443 ssl;
ssl_certificate /home/rocky/proxykeys/certificate.crt;
ssl_certificate_key /home/rocky/proxykeys/privateKey.key;
```

Il faut aussi penser à ouvrir le port 443 à travers le firewall :
```bash
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload
```

Sur le machine web, dans le fichier : /var/www/tp2_nextcloud/config/config.php, on modifie à la ligne "overwrite.cli.url", http par https.

Vous pouvez normalement désormais accéder à votre service via https://web.tp2.linux.

P.S : ne voulez pas fonctionner pour moi, le site est inaccesible en essayant d'activer l'https.  
Pourtant ma configuration est similaire à des collègues qui ont réussi mais je n'ai rien trouvé.
[voici ce que ça fait](files/probleme-https.PNG)
Pourtant le firewall semble bien configuré, les services httpd et nginx sont allumés...
