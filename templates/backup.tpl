#!/bin/bash

# Backup current server data to GCP Cloud Storage
# All Variables are interpolated in Terraform

screen -r ${screen_ses} -X stuff '/save-all\n/save-off\n'

echo "Temporary stopping server saves..."
sleep 10
cd ${mc_home_folder}/${world_name}

zip -r -q ${mc_home_folder}/backup.zip .
gsutil cp -R ${mc_home_folder}/backup.zip gs://${backup_bucket}/$(date "+%Y%m%d-%H%M%S")-${world_name}

rm -f ${mc_home_folder}/backup.zip

screen -r ${screen_ses} -X stuff '/save-on\n'