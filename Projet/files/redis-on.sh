#!/bin/bash

# Nom du service à vérifier/relancer
SERVICE_NAME="redis.service"

# Vérifie si le service est en cours d'exécution
if ! systemctl is-active --quiet $SERVICE_NAME; then
  # Le service n'est pas en cours d'exécution, on le relance
  systemctl start $SERVICE_NAME
fi
