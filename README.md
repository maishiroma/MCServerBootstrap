# Minecraft Server Bootstrap in GCP
Welcome to my small, but humble Terraform module for a Minecraft server, hosted in [Google Cloud Platform](https://console.cloud.google.com/)!

![meme](https://gifimage.net/wp-content/uploads/2017/08/its-alive-gif-20.gif)

## Table Of Contents
- [Overview](#Overview)
- [How to Use](#How-to-Use)
- [Terraform Configuration](#Terraform-Configuration)
- [General Server Management](#General-Server-Management)
- [Modded Server Management](#Modded-Server-Management)
- [Troubleshooting](#Troubleshooting)
- [Future Goals](#Future-Goals)
- [Inspiration](#Inspiration)

## Overview

This project helps streamlines a majority of the steps needed to take when creating a new multiplayer Minecraft Server. Below describes what this Terraform Module creates:
- One GCE instance
    - Assigned the default service account that is scoped to Read Only for Compute API and Read Write to Cloud Storage.
    - Provided metadata scripts for bootstrapping and shutting down.
    - Provided SSH keys to allow access to one outside user
- One persistent SSD to store the Minecraft Server Data
- A custom Network with one Subnetwork
- Firewall rules in the network to only allow specific traffic to:
    - 22
    - 25565
    - icmp
- Ability to add additional TCP/UDP port(s) within the range 49152 to 65535.
- A Cloud Storage Bucket (Two if making a modded MC Server or using Cloud Functions)
- Two Cloud Functions to allow anyone to start/stop the MC Server via curl or Browser

The overall cost to run this project varies greatly with usage and instance size, but it should be fairly minimum if using the project defaults and turning off the instance when no one is playing.

## How to Use

### Requirements

| Name | Version |
|------|---------|
| terraform | > 0.12 |
| archive | >= 2.2.0 |
| google | >= 3.60.0 |
| random | >= 3.1.0 |
| template | >= 2.2.0 |

### Providers

| Name | Version |
|------|---------|
| archive | >= 2.2.0 |
| google | >= 3.60.0 |
| random | >= 3.1.0 |
| template | >= 2.2.0 |

### Pre-Reqs

1. A Google Account (GCP has a [free credit](https://cloud.google.com/free/) sytem where all acccounts can get $300 worth of usage)
2. `terraform` CLI tool, whicch can be gotten [here](https://www.terraform.io/downloads.html)
3. Some light knowledge of Linux, GCP and Terraform
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
    - `Compute Engine API` (Required)
    - `Cloud Storage API` (Required)
    - `IAM Service Account Credentials API` (Only if using Cloud Functions)
    - `Cloud Build API` (Only if using Cloud Functions)
5. Create a Terraform directoty, using this [example](./example) as a basis. Make sure to keep these in mind:
    - Change the __project name__ in `main.tf` if you are not using the project name in there.
    - Create a `terraform.tfvars` and define the following values:
        - `creds_json`
        - `ssh_pub_key_file`
        - `game_whitelist_ips`
        - `admin_whitelist_ips`
    - (Optional) Configure the initial settings of the `server.properties` in the `server_properties.tpl`
    - (Optional) Toggle if this server is a modded one or not via `is_modded`.
6. Run `terraform init`
7. Run `terraform plan` (should get 10 new resources created) and it it looks good, `terraform apply`
8. Sit back for a few mins and your new Minecraft Server should be running at the `ip_address` the `terraform apply` outputs!

> If one made `is_modded = true`, there are a few additonal steps needed to be done. Refer to [Modded Server Management](#Modded-Server-Management) for those steps.

## Terraform Configuration

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin\_whitelist\_ips | The IPs to allow for SSH and ping access, generally reseved for operational work/troubleshooting. If existing\_subnetwork\_name is specified, this will be ignored. | `list(string)` | n/a | yes |
| backup\_cron | How often will the backups run on the instance? This must be written in cron syntax. Defaults to once a week on Sats at 3AM | `string` | `"0 3 * * 6"` | no |
| backup\_length | How many days will a backup last in the bucket? | `number` | `5` | no |
| creds\_json | The absolute path to the credential file to auth to GCP. This needs to be associated with the GCP project that is being used | `string` | n/a | yes |
| disk\_size | How big do you want the SSD disk to be? Defaults to 50 GB | `string` | `"50"` | no |
| enable\_cloud\_func\_management | Do we want to allow for two Cloud Functions to be created to allow anyone to start/stop the MC Server via HTTP request? Default to false. | `bool` | `false` | no |
| existing\_subnetwork\_name | An existing subnetwork to leverage placing the instances. Assumes that the firewalls in the subnetwork are already configured. | `string` | `""` | no |
| extra\_tcp\_game\_ports | Extra TCP ports to open on the MC instance. Note that these should be in the range of 49152 to 65535. | `list(string)` | `[]` | no |
| extra\_udp\_game\_ports | Extra udp ports to open on the MC instance. Note that these should be in the range of 49152 to 65535. | `list(string)` | `[]` | no |
| game\_whitelist\_ips | The IPs used to connect to the Minecraft server itself through the MC client. If existing\_subnetwork\_name is specified, this will be ignored. | `list(string)` | n/a | yes |
| gcp\_project\_id | The Google Compute Platform Project ID. This is the ID of the project that your infrastructure is deployed under. | `string` | n/a | yes |
| is\_modded | Is this Minecraft server modded? Defaults to false. | `bool` | `false` | no |
| machine\_type | The type of machine to spin up. If the instance is struggling, it might be worthwhile to use stronger machines. | `string` | `"n1-standard-2"` | no |
| mc\_forge\_server\_download\_link | The direct download link to MC forge for modding support. Defaults to version 1.16.5. | `string` | `"https://files.minecraftforge.net/maven/net/minecraftforge/forge/1.16.5-36.1.0/forge-1.16.5-36.1.0-installer.jar"` | no |
| mc\_home\_folder | The location of the Minecraft server files on the instance | `string` | `"/home/minecraft"` | no |
| mc\_server\_download\_link | The direct download link to download the server jar. Defaults to a link with 1.16.5. | `string` | `"https://launcher.mojang.com/v1/objects/35139deedbd5182953cf1caa23835da59ca3d7cd/server.jar"` | no |
| override\_server\_activate\_cmd | Should the bootstrap use a different server command than java -Xms server\_min\_ram -Xmx server\_max\_ram -jar /home/minecraft/server.jar nogui? If left blank, uses said default command | `string` | `""` | no |
| project\_name | The name of the project. Not to be confused with the project name in GCP; this is moreso a terraform project name. | `string` | `"mc-server-bootstrap"` | no |
| region | The region used to place these resources. Defaults to us-west2. | `string` | `"us-west2"` | no |
| server\_image | The boot image used on the server. Defaults to `ubuntu-1804-bionic-v20191211` | `string` | `"ubuntu-1804-bionic-v20191211"` | no |
| server\_max\_ram | The maximum amount of RAM to allocate to the server process | `string` | `"7G"` | no |
| server\_min\_ram | The minimum amount of RAM to allocate to the server process | `string` | `"1G"` | no |
| server\_property\_template | The file path used to parse the server property file for the MC server. Defaults to the standard one in the module | `string` | `"./templates/server_properties.tpl"` | no |
| server\_world\_name | The name of the world that the server will be using. By default, this is just world. | `string` | `"world"` | no |
| ssh\_pub\_key\_file | The SSH public key file to use to connect to the instance as the user specified in ssh\_user | `string` | n/a | yes |
| ssh\_user | The name of the user to allow to SSH into the instance | `string` | `"iamall"` | no |
| zone\_prefix | The zone prefix used for deployments. Defaults to 'a'. | `string` | `"a"` | no |

### Outputs

| Name | Description |
|------|-------------|
| cloud\_funcs\_http\_triggers | The URLs that correspond to the Cloud Functions, if created |
| created\_subnetwork | The name of the created subnetwork that was provisioned in this module. Can be used to provision more servers in the same network if desired |
| ext\_bucket\_name | The name of the Cloud Storage Bucket used to hold any persistent MC data. |
| server\_ip\_address | The ephimeral public IP address used to access this instance. |

### Nuances

While most of the configuration has verbose descriptions, there are some options that have a bit more complexity:

| Terraform Variable     | Notes        |
| :--------------------- | :----------: |
| `machine_type`         | Depending on what you use, this can greatly affect the price of running this. The most cost effective, [N1](https://cloud.google.com/compute/vm-instance-pricing#n1_predefined) should be the one you want to use, unless your server will be hostin a massive amount of players.
| `game_whitelist_ips`           | To ban/allow players into the game, it is handled on the infrastructure level. As such, make sure to get your friend's IPs and place them in here, so they can acces this instance! |
| `admin_whitelist_ips` | This should only be restricted to the person that is administrating this server. Not correlated to `admin` power in Minecraft; this is moreso system admin access |
| `mc_server_download_link` | One easy way to get different versions of Minecraft can be gotten at [this](https://mcversions.net/) link. Just find the right server version, right click on the download URL and save it, placing it in this value. |
|`mc_forge_server_download_link` | There are a multitude of mod loaders for MC, which would make this project rise in complexity. For simplicity sake, the project supports [MC Forge](https://files.minecraftforge.net/) as the mod loader of choice. Any other one is not supported. |
| `server_property_template` | This could change consistenty in the server, making it tricky to keep track of in this code. As such, any new changes made after the initial deployment of the server will __NOT__ be reflected in code. To use a new config if one changed it outside of the server, one must manually go onto the instance and edit the config to match what is down in code. |
| `existing_subnetwork_name` | This allows for multiple instances of this module to be deployed in the same network, for easier management. To properly use this, make sure one module of this stack is deployed, with the other module calls referencing the `created_subnetwork` output of the first module. |
| `override_server_activate_cmd` | There is a slight change in the logic for bootstrapping Forge in 1.18, specifically with the nonexistance of the server jar to run after installing Forge. Instead, they change running the command to just a bash script, `run.sh`. This needs to be reflected in the command, hence this variable. |
| `enable_cloud_func_management` | By default, only those who have SSH access to the server and/or GCP console can turn off/on the server. However, when this is set to `true`, the module outputs two URLs that allow **anyone** to turn off/on the instance by visiting said link. |

## General Server Management

By default, rebooting and respinning up an instance will automatically set up the Minecraft Server for you. Backups of your world are auto created when the server is terminated. No need for any action on your part!

However, if needed, the following server actions can be performed:
- **Stopping the Server**
    - `/home/minecraft/scripts/stop.sh` (default location)
        - Stops the Minecraft server (not the instance)
            - Ex: `$ cd /home/minecraft/scripts && sudo ./stop.sh`
        - To start up the Minecraft server again, run the `restart.sh` script
- **Restarting the Server**
    - `/home/minecraft/scripts/restart.sh` (default location)
        - Restarts the Minecraft server (not the instance)
            - Ex: `$ cd /home/minecraft/scripts && sudo ./restart.sh`
- **Backup World**
    - `/home/minecraft/scripts/backup.sh` (default location)
        - Pushes up current state of server to Cloud Storage Buckets.
            - Ex: `$ cd /home/minecraft/scripts && sudo ./backup.sh`
        - This script will also be triggered automatically by a cronjob. By default it runs once a week on Sat at 3AM.
- **Restore To Backup**
    - `/home/minecraft/scripts/restore_backup.sh` (default location)
        - Restores the server world to the specified state
            - Ex: `$ cd /home/minecraft/scripts && sudo ./restore_backup.sh nameOfBackup`

If `enable_cloud_func_management` is set to `true`, *anyone* with the outputted URLs that the module outputs at `cloud_funcs_http_triggers` can turn off/on the instance. This can be helpful if one wants to give more control to the players on when to play/stop playing.

> NOTE: By setting `enable_cloud_func_management` to true, you are **RESPONSIBLE** for making sure that those URLs are not misused. Please be wary of that.

There is also a python script called `toggle_gcp_instance`, that can be invoked manually to help automate instance shutoff/startup. Refer to it [here](./scripts/toggle_gcp_instance/README.md) for more details.

## Modded Server Management

Along with all of the features/scripts mentioned in the [General Server Management](#General-Server-Management), there are a few extra steps that need to happen before the server is completly ready.

### Extra Steps
1. Once the server is done bootstrapping (easiest is to tail the logs for the MC server in `/home/minecraft/logs`), placce the mods that you want to use in the provided Cloud Storage Bucket (should have the suffix, `ext` at the end.)
    - Make sure these mods are placed in the `mod` prefix in the bucket (i.e. `bucketName/mods/modName.jar`)
2. SSH into the server and navigate to the `scripts` directory (defaults at `/home/minecraft/scripts`) and run the following script:

```
sudo ./mod_refresh.sh
```

3. Once that is done, wait for a few moments as the MC server restarts up.

> For the mods to show up on player's screen, they **all** need to have that mod installed (unless it is a server side mod)!

### Extra Scripts
As mentioned previously, all modded servers have an additional script located in the `script` directory:
- **Syncronize Mods**
    - `/home/minecraft/scripts/mod_refresh.sh` (default location)
        - Syncs up the `mods` folder on the instance to match the current state of the Cloud Storage Bucket holding said mods.
            - Ex: `$ cd /home/minecraft/scripts && sudo ./mod_refresh.sh`

## Troubleshooting
- *Problem*: The server has not been started, even though the instance has been respun/started!
    - **Resolution**: It could be the startup script failed to execute. Taint the GCP instance in Terraform and reapply the Terraform configuration to auto respin the instance and wait for the instance to spin up again.
- *Problem*: I'm not sure if the startup script executed?
    - **Resolution**: Depending on the image you are using, there is a way to tell the instance to rerun the starup script. Refer to the link [here](https://cloud.google.com/compute/docs/startupscript#rerunthescript) for more details.
- *Problem*: I want to debug the running instance, what are my options?
    - **Resolution**: Check this [link](https://cloud.google.com/compute/docs/startupscript#viewing_startup_script_logs) to view any startup script logs. For the minecraft server itself, the logs can be viewed in the minecraft folder under `logs`.
- *Problem*: Looking on the instance's logs, there's a crash in the Minecraft server, how can I fix this?
    - **Resolution**: The following solutions should be attempted in order from top to bottom, stopping once a resolution has been found:
        - Run the `restart.sh` script in the `scripts` folder to restart the Minecraft server
        - Reboot the instance (`sudo reboot`) or recreate the instance in Terraform
        - Restore from a backup using `restore_backup.sh`
- *Problem*: I need to start my world from scratch, what can I do?
    - **Resolution**: From least to most destructive, you have the following options (make sure to stop the minecraft server first via `stop.sh`!):
        - Delete the `world` folder and run `restart.sh` to start up the server again
        - Remove all contents of the `minecraft` folder and rerun the startup script
        - Perform a `terraform destroy` and then a `terraform apply`
- *Problem*: I created the Cloud Functions, but when I navigate to them on my browser or `curl`, it takes a long time!
    - **Resolution**: *Be patient!* It is normal to have those links appear *hanging* for a few seconds. You will **ALWAYS** get a response back via plain HTTP after visiting those links, so just keep the tab open/command running.
- *Problem*: I ran the Cloud Function and it gave me an error on something failed!
    - **Resolution**: s the message suggests, check the logs when trying to invoke the function. There is enough verbal output to allow one to troubleshoot the function.

## Inspiration

- This [blog](https://cloud.google.com/blog/products/it-ops/brick-by-brick-learn-gcp-by-setting-up-a-minecraft-server) gave me the initial idea on how this can be easily done nowadays
- My current gig involving myself being inmersed in the cloud
- A certain coworker who if you are reading this, you know who exactly :wink: