#!/bin/bash

# This will run when the instance has spun down

${mc_script_location}/backup.sh

screen -S ${screen_ses} -r -X stuff '/stop\n'