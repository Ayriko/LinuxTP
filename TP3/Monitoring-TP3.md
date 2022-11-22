# Module 5 : Monitoring

## 1/ Installation de Netdata

Sur la machine que vous souhaitez surveiller :  

```bash
sudo dnf install epel-release -y
sudo dnf install wget -y
sudo wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh
//répondre yes à chaque demande
sudo systemctl start netdata
sudo systemctl enable netdata
sudo systemctl status netdata
//vérifier que le service est bien allumé
sudo firewall-cmd --permanent --add-port=19999/tcp
sudo firewall-cmd --reload
```

L'interface de netdate est accesible depuis ce lien :   
`http://<Enter Your IP Here>:19999/`

## 2/ Mise en place des alertes discord

Sur votre discord, il va falloir créer et récupérer l'adresse d'un webhook.  
Rendez-vous dans les paramètres du serveur et dans l'onglet **Intégrations**.  
Ici vous pourrez créer et consulter vos webhooks.  
Créez-en un avec les infos que vous souhaitez mais récupérer son URL.  

Une fois fait, sur votre machine, utilisez cette commande :
```bash
sudo /etc/netdata/edit-config health_alarm_notify.conf
```
et ajoutez à la toute fin, en modifiant l'URL par celle de votre webhook :
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

## 3/ Stress de la machine pour tester le fonctionnement

Pour vérifier que les alertes fonctionnent, on va utiliser stress-ng.  

```bash
sudo dnf install stress-ng -y
```
Et pour tester, on peut utiliser cette configuration recommandée :
```bash
stress-ng --cpu 1 --vm 1 --hdd 1 --fork 1 --switch 1 --timeout 600 --metrics
```

-> [Exemple d'alertes](files/alert-discord.PNG)