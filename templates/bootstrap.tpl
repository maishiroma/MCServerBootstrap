#!/bin/bash
set -e

# This will run during initial launch and relaunches of the instance (i.e. when it is destroyed)
# All variables in here are interpolated into Terraform

prepare_ssd() {
    if [ ! -d "${mc_home_folder}" ]; then
        mkdir ${mc_home_folder}
    fi

    if [ "$(blkid -o value --match-tag TYPE ${mount_location})" != "ext4" ]; then
        mkfs -t ext4 ${mount_location}
    fi
    
    if [ $(mount | grep -c ${mount_location}) != 1 ]; then
        mount -t ext4 ${mount_location} ${mc_home_folder}
    fi

    if [ ! -d "${mc_script_location}" ]; then
        mkdir ${mc_script_location}
    fi
}

install_pre_req() {
    add-apt-repository -y ppa:openjdk-r/ppa 
    apt-get update
    apt-get install -y default-jre-headless openjdk-17-jdk zip unzip screen less
    
    if [ $(command -v gsutil &> /dev/null)  ]; then
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

        apt-get install -y gsutil
        apt-get install -y google-cloud-sdk
    fi
}

setup_mc_server() {
    cd ${mc_home_folder}
    if [ ! -f "${mc_home_folder}/eula.txt" ]; then
        if [ "${is_modded}" == "true" ]; then             
            installer_name=$(basename ${mc_server_download_link})
            result_name=$${installer_name/-installer/}
            
            wget -O ${mc_home_folder}/$${installer_name} ${mc_server_download_link}
            java -jar ${mc_home_folder}/$${installer_name} --installServer
            
            rm -f ${mc_home_folder}/$${installer_name}
            if [ ! -f "${mc_home_folder}/user_jvm_args.txt" ]; then
                mv -f ${mc_home_folder}/$${result_name} ${mc_home_folder}/${jar_name}
            else
                echo "" >> ${mc_home_folder}/user_jvm_args.txt
                echo "-Xms${min_ram}" >> ${mc_home_folder}/user_jvm_args.txt
                echo "-Xmx${max_ram}" >> ${mc_home_folder}/user_jvm_args.txt
            fi
        else
            wget -O ${mc_home_folder}/${jar_name} ${mc_server_download_link}
        fi

        if ! screen -list | grep -q "${screen_ses}"; then
            set +e
            ${screen_cmd}
            set -e
        fi

        sed -i 's/eula=false/eula=true/g' ${mc_home_folder}/eula.txt
    fi

    if ! screen -list | grep -q "${screen_ses}"; then
        command="${screen_cmd}" screen -S ${screen_ses} -d -m bash -c '$command; exec bash'
    fi
}

place_metadata_config() {
    gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${stop_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/stop.sh
    gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${backup_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/backup.sh
    gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${restore_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/restore_backup.sh
    gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${restart_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/restart.sh

    chmod 755 ${mc_script_location}/stop.sh
    chmod 755 ${mc_script_location}/backup.sh
    chmod 755 ${mc_script_location}/restore_backup.sh
    chmod 755 ${mc_script_location}/restart.sh

    if [ "${is_modded}" == "true" ]; then
        gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${mod_refresh_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_script_location}/mod_refresh.sh
        chmod 755 ${mc_script_location}/mod_refresh.sh
    fi

    if [ ! -f "${mc_home_folder}/server.properties" ]; then
        gcloud compute instances describe ${instance_name} --zone ${zone_name} --flatten="metadata[${mc_server_prop_key}]" | tail -n +2 - | awk '{$1=$1;print}' > ${mc_home_folder}/server.properties
        chmod 644 ${mc_home_folder}/server.properties
    fi
}

setup_cron() {
    echo "${backup_cron} ${mc_script_location}/backup.sh" | crontab -
}

stop_mc_server() {
    if [[ -d ${mc_home_folder} ]] && [[ ! $(command -v screen &> /dev/null) ]]; then
        if screen -list | grep -q "${screen_ses}"; then
            cd ${mc_home_folder}
            screen -S ${screen_ses} -r -X stuff '/stop\n'
            sleep 10
            screen -S ${screen_ses} -p 0 -X quit
        fi
    fi
}

## MAIN
prepare_ssd
stop_mc_server
install_pre_req
place_metadata_config
setup_cron
setup_mc_server

echo "Finished running bootstrap!"