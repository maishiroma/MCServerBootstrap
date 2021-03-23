#!/bin/bash

# Restores  the server world to the passed in Cloud Object
# All Variables are interpolated in Terraform

cd ${mc_home_folder}
screen -S ${screen_ses} -r -X stuff '/stop\n'
echo "Stopping MC Server..."
sleep 10
screen -S ${screen_ses} -p 0 -X quit

mv -f ${mc_home_folder}/world ${mc_home_folder}/world_old
gsutil cp gs://${backup_bucket}/$1 ${mc_home_folder}/backup.zip
mkdir ${mc_home_folder}/world
unzip -q ${mc_home_folder}/backup.zip -d ${mc_home_folder}/world
rm -f ${mc_home_folder}/backup.zip

command="${screen_cmd}" screen -S ${screen_ses} -d -m bash -c '$command; exec bash'
echo "Restored backup. It will take a few seconds for the server to be back up."