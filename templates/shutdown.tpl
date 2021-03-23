#!/bin/bash

# This will run when the instance has spun down

screen -S ${screen_ses} -r -X stuff '/stop\n'