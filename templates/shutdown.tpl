#!/bin/bash

# This will run when the instance has spun down

### Variables
SCREEN_SES="mc_server"


screen -S $SCREEN_SES -r -X stuff '/stop\n'