# Toggle GCP Instance
This directory contains a Python script that can help automate spinning down, up and viewing the current status of a GCP instance.

## Requirements
- Python 3.9.1
- All dependencies listed in `requirements.txt`

## How to use
This script is ingested two ways:

1. Local
    - `pip install requirements.txt`
    - `python3 main.py --project <project_name> --zone <zone_name> --tag <tag_name> --mode [start, stop, status]`
        - This requires the env variable, `GOOGLE_APPLICATION_CREDENTIALS` to be pointing to a JSON file in your computer that authenticates to your GCP project
            - The creds need to have permission to list, get, start, stop instances
2. Cloud Functions
    - This is automatically ingested and performed by Cloud Functions when you invoke their corresponding URLs.
        - Credentials are obtained through the IAM role the Cloud Function is provided

More details on this script can be viewed in the `main.py` file