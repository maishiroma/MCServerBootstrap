"""
This script aids in managing a GCP instance in the cloud. There are two ways to run this:
    - Locally, using the env var, GOOGLE_APPLICATION_CREDENTIALS, to authenticate
    - Cloud Functions

The features of this include:
- Ability to turn on and off the instance
- Check the status of the instance

How to use:
    Locally -> python3 main.py --project ... --zone ... --tag ... --mode ...
        - project: The GCP project that the instance is in
        - zone: The Availability zone that the instance is in
        - tag : The project tag of an instance
        - mode: What option to perform on this? Either
            - start: Start instance
            - stop: Stop instance
            - status: Read status of instance (default)
    
    Cloud Function -> Invoked via URL call (enter through http_post function)
        - Just need to pass in the following env vars:
            - INST_ZONE: The Availability zone that the instance is in
            - INST_TAG: The project tag of an instance
        - mode: HTTP Option. Can pass in
            - start: Start instance
            - stop: Stop instance
"""

import argparse
import os
import sys
import time

import googleapiclient.discovery as gcp

loader = ["|", "\\", "|", "/"]
max_tries = 10


def parse_parameters():
    """
    Helper script to parse CLI args. Note that this is only done
    when performed locally
    """

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--mode",
        help="What mode to run this script?",
        choices=["start", "stop", "status"],
        default="status",
        type=str.lower,
    )
    parser.add_argument("--project", help="The GCP project that the instance is in.", type=str.lower, default="")
    parser.add_argument("--zone", help="The Availability zone that the instance is in.", type=str.lower, default="")
    parser.add_argument("--tag", help="The project instance tag to search instances for.", type=str.lower, default="")
    result = parser.parse_args()

    if result.tag == "" or result.zone == "" or result.project == "":
        print("Missing parameters, please refer to -h for options needed")
        sys.exit(1)

    return result


def return_instance_name(client, instance_project_tag):
    """
    Using the instance tag, we find the proper instance and return its name
    """

    results = client.instances().list(project=PROJECT, zone=ZONE).execute()
    for instance in results["items"]:
        if instance["labels"]["project"] == instance_project_tag:
            return instance["name"]
    return None


def return_instance_status(client, instance_name):
    """
    Given the instance name, we return two things on this instance as a dict:
        - Status of it running
        - Public IP (if it has one)
    """

    result = client.instances().get(project=PROJECT, zone=ZONE, instance=instance_name).execute()
    status = result["status"]
    public_ip = result["networkInterfaces"][0]["accessConfigs"][0].get("natIP", "None")

    return {"status": status, "public_ip": public_ip}


def start_instance(client, instance_name):
    """
    We start up the instance if it has been stopped. Returns True if succesful. Returns
    False if not
    """

    if return_instance_status(client, instance_name)["status"] == "TERMINATED":
        print("Preparing to start instance, {id}".format(id=instance_name))
        client.instances().start(project=PROJECT, zone=ZONE, instance=instance_name).execute()

        loader_index = 0
        curr_try = 0
        while return_instance_status(client, instance_name)["status"] != "RUNNING":
            print("Waiting for instance to go online {load}".format(load=loader[loader_index]), end="\r", flush=True)

            time.sleep(5)

            curr_try += 1
            if curr_try >= max_tries:
                print("Instance still spinning up, check console for status")
                return True

            loader_index += 1
            if loader_index >= len(loader):
                loader_index = 0

        print("Instance is now running!")
        return True
    print("Instance is already running!")
    return False


def stop_instance(client, instance_name):
    """
    We stop the instance if it has been running. Returns true if sucessful.
    """

    if return_instance_status(client, instance_name)["status"] == "RUNNING":
        print("Preparing to stop instance, {id}".format(id=instance_name))
        client.instances().stop(project=PROJECT, zone=ZONE, instance=instance_name).execute()

        loader_index = 0
        curr_try = 0
        while return_instance_status(client, instance_name)["status"] != "STOPPED":
            print("Waiting for instance to go offline {load}".format(load=loader[loader_index]), end="\r", flush=True)

            time.sleep(5)

            curr_try += 1
            if curr_try >= max_tries:
                print("Instance still spinning down, check console for status")
                return True

            loader_index += 1
            if loader_index >= len(loader):
                loader_index = 0

        print("Instance is now stopped!")
        return True
    print("Instance is already stopped!")
    return False


def http_post(request):
    """
    Entrypoint into this function when invoked by GCP Cloud Functions. All core
    values are passed in as env values. One value is passed in as a HTTP arg.

    Returns a string that is used to be parsed onto the response
    """

    mode = os.environ.get("MODE", "")
    tag = os.environ.get("INST_TAG", "")

    if mode == "" or tag == "":
        return "Key values, mode or tag missing. Please consult owner of deployment."
    else:
        instance_name = return_instance_name(client, tag)

        if mode == "start":
            result = start_instance(client, instance_name)
            new_status = return_instance_status(client, instance_name)
            if result is True:
                return "MC Server has started. Give it a minute before connecting. IP: {ip}".format(
                    ip=new_status["public_ip"]
                )
            else:
                return "MC Server is already running at {ip}!".format(ip=new_status["public_ip"])
        elif mode == "stop":
            result = stop_instance(client, instance_name)
            if result is True:
                return "MC Server has stopped. Thanks for saving money! <3"
            else:
                return "MC Server has already stopped."
        else:
            return "Invalid mode. Check URL used to invoke me?"


def local_exec():
    """
    Called when locally invoking this script.

    Returns nothing. Used CLI flags to parse
    """

    instance_name = return_instance_name(client, args.tag)
    if args.mode == "start":
        ending = start_instance(client, instance_name)
        instance_details = return_instance_status(client, instance_name)
        print("Public IP: {ip}".format(ip=instance_details["public_ip"]))
    elif args.mode == "stop":
        stop_instance(client, instance_name)
    elif args.mode == "status":
        instance_details = return_instance_status(client, instance_name)
        print(
            "Instance: {id}\nStatus: {state}\nPublic IP: {ip}".format(
                id=instance_name, state=instance_details["status"], ip=instance_details["public_ip"]
            )
        )
    else:
        print("Invalid mode, exiting script...")
        sys.exit(1)


## Main Area

# If running locally, set env var, GOOGLE_APPLICATION_CREDENTIALS
if os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "") != "":
    print("Running script locally, setting proper variables...")

    args = parse_parameters()
    PROJECT = args.project
    ZONE = args.zone
else:
    print("Running script on Cloud Functions, setting proper variables...")

    PROJECT = os.environ.get("PROJECT", "")
    ZONE = os.environ.get("INST_ZONE", "")

# Running locally uses creds sourced locally
# Running on Cloud Functions uses IAM role of Cloud Function
client = gcp.build("compute", "v1")

if __name__ == "__main__":
    local_exec()
