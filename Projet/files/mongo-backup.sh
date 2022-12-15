#!/bin/bash

TODAY=`date +"%d%b%Y"`
MONGO_USER='avraeBot'
MONGO_PASSWD='avraepwd'
DATABASE_NAME='avrae'

echo "Running backup"
cd /home/rocky/mongo-dump
mongodump --authenticationDatabase="admin" -u=${MONGO_USER} -p=${MONGO_PASSWD} -d=${DB_NAME} --out /home/rocky/mongo-dump/${TODAY} --gzip