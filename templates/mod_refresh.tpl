#!/bin/bash

# Refreshes the mod folder with the current contents of ${ext_bucket}/mods
# All variables in here are interpolated into Terraform

cd ${mc_home_folder}
echo "Stopping MC Server..."
screen -S ${screen_ses} -r -X stuff '/stop\n'
sleep 10
screen -S ${screen_ses} -p 0 -X quit

rm -rf ${mc_home_folder}/mods/*
gsutil cp gs://${ext_bucket}/mods/* ${mc_home_folder}/mods/.

command="${screen_cmd}" screen -S ${screen_ses} -d -m bash -c '$command; exec bash'
echo "Refreshed mod folder. Server will be back up in a few moments!"