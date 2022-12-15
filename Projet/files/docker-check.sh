#!/bin/bash

# Change to the directory /home/rocky/avrae or the modify with the path to your docker
cd /home/rocky/avrae

# Check if the Docker container is running
if ! docker ps -q --filter name=my-container
then
  # Start the Docker container if it is not running
  docker start my-container
fi
