# Minecraft Server Bootstrap in GCP
Welcome to my small, but humble infrastructure development for a Minecraft server, hosted in [Google Cloud Platform](https://console.cloud.google.com/) (GCP)!

![meme](https://gifimage.net/wp-content/uploads/2017/08/its-alive-gif-20.gif)

## Table Of Contents
- [Overview](#Overview)
- [How to Use](#How-to-Use)
- [General Server Management](#General-Server-Management)
- [Terraform Configuration Nuances](#Terraform-Configuration-Nuances)
- [Future Goals](#Future-Goals)
- [Inspiration](#Inspiration)

## Overview

This project helps streamlines a majority of the steps needed to take when creating a new multiplayer Minecraft Server. Below describes what this repository creates:
- One GCE instance
    - Assigned the default service account that is scoped to Read Only for Compute API and Read Write to Cloud Storage.
    - Provided metadata scripts for bootstrapping and shutting down.
    - Provided SSH keys to allow access to one outside user
- One persistent SSD to store the Minecraft Server Data
- One Static IP
- A custom Network with one Subnetwork
- Firewaall rules in the network to only allow specific traffic to:
    - 22
    - 25565
    - icmp
- A Cloud Storage Bucket

The overall cost to run this project varies greatly with usage and instance size, but it should be fairly mimimum if using the project defaults.

## How to Use

### Pre-Reqs

1. A Google Account (GCP has a [free credit](https://cloud.google.com/free/) sytem where all acccounts can get $300 worth of usage)
2. `terraform` CLI tool, whicch can be gotten [here](https://www.terraform.io/downloads.html)
3. Some light knowledge of Linux, GCP
4. Some familiarity with Minecraft server hosting

### Steps

1. Sign into your Google account and log into [GCP](https://console.cloud.google.com/)
2. Create a new __project__ and remember the `project_id` that GCP assigns it.
3. In that new __project__, create a new __service account__ (`IAM & Admin -> Service Accounts`)
    - Name the account to whatever you desire
    - For the __Role__, specify `Owner`
    - Once done, navigate to that new __service account__ and select `Keys -> Create New Key -> JSON`
    - Save this key in a secure location on your computer (I recommend `~/.ssh`).

> Be careful with that key! __It has admin API access to your entire GCP account__, meaning anything can be deployed in GCP using said key. More savy GCP users can use a role that is less wide in scope for this project, but for the sake of this walkthrough, you can proceed with these permissions.

4. Enable the following APIs in the GCP Console:
    - `Compute Engine API` 
5. Clone this repository onto your computer and perform the follwing steps:
    - Change the __project name__ in `main.tf` if you are not using the project name in there.
    - Create a `terraform.tfvars` and define the following values:
        - `creds_json`
        - `ssh_pub_key_file`
        - `game_whitelist_ips`
        - `admin_whitelist_ips`
    - Configure the initial settings of the `server.properties` in the `bootstrap.tpl`
        - Note that any changes made to this _after_ the server initially spins up will __NOT__ take place
6. Run `terraform init`
7. Run `terraform plan` (should get 11 new resources created) and it it looks good, `terraform apply`
8. Sit back for a few mins and your new Minecraft Server should be running at the `ip_address` the `terraform apply` outputs!

## Terraform Configuration Nuances

While most of the configuration has verbose descriptions, there are some that are worthwhile to put here:

| Terraform Variable     | Notes        |
| :--------------------- | :----------: |
| `machine_type`         | Depending on what you use, this can greatly affect the price of running this. The most cost effective, [N1](https://cloud.google.com/compute/vm-instance-pricing#n1_predefined) should be the one you want to use, unless your server will be hostin a massive amount of players.
| `game_whitelist_ips`           | To ban/allow players into the game, it is handled on the infrastructure level. As such, make sure to get your friend's IPs and place them in here, so they can acces this instance! |
| `admin_whitelist_ips` | This should only be restricted to the person that is administrating this server. Not correlated to `admin` power in Minecraft; this is moreso system admin access |
| `mc_server_download_link` | One easy way to get different versions of Minecraft can be gotten at [this](https://mcversions.net/) link. Just find the right server version, right click on the download URL and save it, placing it in this value. |

## General Server Management

By default, rebooting and respinning up an instance will automatically set up the server for you. No need for any action on you!

Backup, restores and restarts can be performed via the following scripts:
- `/home/minecraft/scripts/backup.sh` (default location)
    - Pushes up current state of server to Cloud Storage Buckets.
    - Ex: `$ cd /home/minecraft/scripts && sudo ./backup.sh`
- `/home/minecraft/scripts/restore_backup.sh` (default location)
    - Restores the server world to the specified state
    - Ex: `$ cd /home/minecraft/scripts && sudo ./restore_backup.sh nameOfBaackup`
- `/home/minecraft/scripts/restart.sh` (default location)
    - Restarts the Minecraft server (not the instance)
    - Ex: `$ cd /home/minecraft/scripts && sudo ./restart.sh`

To keep costs low, it is a good idea to stop this instance when it is not in use. This can be done via the GCP console and/or the CLI if one has that configured.

## Future Goals

- [] Create automated process to perform backups (cron job, ansible)
- [] Create a process to restore backups, possibly allowing the user to see a list of all backups in bucket
- [] Add a curated list of Minecraft versions that allows the end user to just specify the `version` instead of a URL link
- [] Find a way to more easily set up the initial server properies, instead of being in the metadata

## Inspiration

- This [blog](https://cloud.google.com/blog/products/it-ops/brick-by-brick-learn-gcp-by-setting-up-a-minecraft-server) gave me the initial idea on how this can be easily done nowadays
- My current gig involving myself being inmersed in the cloud
- A certain coworker who if you are reading this, you know who exactly :wink: