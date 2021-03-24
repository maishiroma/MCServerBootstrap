#!/bin/bash
set -e

# This will run during initial launch and relaunches of the instance (i.e. when it is destroyed)
# All variables in here are interpolated into Terraform

prepare_ssd() {
    if [ ! -d "${mc_home_folder}" ]; then
        mkdir ${mc_home_folder}
    fi

    if [ "$(blkid -o value --match-tag TYPE /dev/sdb)" != "ext4" ]; then
        mkfs -t ext4 /dev/sdb
    fi
    mount -t ext4 /dev/sdb ${mc_home_folder}
    
    if [ ! -d "${mc_script_location}" ]; then
        mkdir ${mc_script_location}
    fi
}

install_pre_req() {
    if [ ! $(command -v gsutil &> /dev/null)  ]; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

        apt-get update
        apt-get install -y gsutil
        apt-get install -y default-jre-headless zip screen less google-cloud-sdk
    fi
}

setup_mc_server() {
    cd ${mc_home_folder}
    if [ ! -f "${mc_home_folder}/${jar_name}" ]; then
        wget -O ${mc_home_folder}/${jar_name} ${mc_server_download_link}

        set +e
        ${screen_cmd}
        set -e

        sed -i 's/eula=false/eula=true/g' ${mc_home_folder}/eula.txt
    fi

    command="${screen_cmd}" screen -S ${screen_ses} -d -m bash -c '$command; exec bash'
}

place_metadata_config() {
    gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${backup_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/backup.sh
    gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${restore_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/restore_backup.sh
    gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${restart_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/restart.sh

    chmod 755 ${mc_script_location}/backup.sh
    chmod 755 ${mc_script_location}/restore_backup.sh
    chmod 755 ${mc_script_location}/restart.sh

    if [ ! -f "${mc_home_folder}/server.properties" ]; then
        gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${mc_server_prop_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_home_folder}/server.properties
        chmod 644 ${mc_home_folder}/server.properties
    fi
}

setup_cron() {
    echo "${backup_cron} ${mc_script_location}/backup.sh" | crontab -
}

## MAIN
install_pre_req
prepare_ssd
place_metadata_config
setup_cron
setup_mc_server