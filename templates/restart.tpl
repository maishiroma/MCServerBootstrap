#!/bin/bash

# Restarts MC Server
# All Variables are interpolated in Terraform

cd ${mc_home_folder}
echo "Now restarting MC Server..."
screen -S ${screen_ses} -r -X stuff '/stop\n'
sleep 10
screen -S ${screen_ses} -p 0 -X quit

command="${screen_cmd}" screen -S ${screen_ses} -d -m bash -c '$command; exec bash'
echo "Restarted MC server! Give it a few seconds to reload up!"