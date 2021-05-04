#!/bin/bash

# Stops a running MC Server
# All Variables are interpolated in Terraform

cd ${mc_home_folder}
echo "Stopping MC Server..."
screen -S ${screen_ses} -r -X stuff '/stop\n'
sleep 10

echo "Stopped MC server session! To start it up again, run the restart.sh script!"