#!/bin/bash
echo "Stopping docker containers"
docker container stop conjur-master
docker container stop conjur-cli
docker container stop database

echo "Removing docker containers"
docker container rm conjur-master
docker container rm conjur-cli
docker container rm database

echo "Removing Install files"
rm -rf setup.log data_key ws_admin_key
