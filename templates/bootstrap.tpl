#!/bin/bash
set -e
set -x

# This will run during initial launch and relaunches of the instance (i.e. when it is destroyed)
# All variables in here are interpolated into Terraform

## Global Vars
JAR_NAME="server.jar"
SCREEN_SES="mc_server"
SCREEN_CMD="java -Xms${server_min_ram} -Xmx${server_max_ram} -jar ${mc_home_folder}/$JAR_NAME nogui"

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

        configure_backups
        configure_restore_backup
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
    if [ ! -f "${mc_home_folder}/$JAR_NAME" ]; then
        wget -O ${mc_home_folder}/$JAR_NAME ${mc_server_download_link}

        set +e
        $SCREEN_CMD
        set -e

        sed -i 's/eula=false/eula=true/g' ${mc_home_folder}/eula.txt
    fi

    command="$SCREEN_CMD" screen -S $SCREEN_SES -d -m bash -c '$command; exec bash'
}

configure_backups() {
    cat << EOF > ${mc_script_location}/backup.sh
#!/bin/bash
screen -r $SCREEN_SES -X stuff '/save-all\n/save-off\n'
echo "Temp stopping server saves..."
sleep 10
cd ${mc_home_folder}/world
/usr/bin/zip -r -q ${mc_home_folder}/backup.zip .
/usr/bin/gsutil cp -R ${mc_home_folder}/backup.zip gs://${backup_bucket}/\$(date "+%Y%m%d-%H%M%S")-world
rm -f ${mc_home_folder}/backup.zip
screen -r $SCREEN_SES -X stuff '/save-on\n'
EOF

    chmod 755 ${mc_script_location}/backup.sh
}

configure_restore_backup() {
     cat << EOF > ${mc_script_location}/restore_backup.sh
#!/bin/bash
cd ${mc_home_folder}
screen -S $SCREEN_SES -r -X stuff '/stop\n'
echo "Stopping MC Server..."
sleep 10
screen -S $SCREEN_SES -p 0 -X quit
mv -f ${mc_home_folder}/world ${mc_home_folder}/world_old
/usr/bin/gsutil cp gs://${backup_bucket}/\$1 ${mc_home_folder}/backup.zip
mkdir ${mc_home_folder}/world
/usr/bin/unzip -q ${mc_home_folder}/backup.zip -d ${mc_home_folder}/world
rm -f ${mc_home_folder}/backup.zip
command="$SCREEN_CMD" screen -S $SCREEN_SES -d -m bash -c '\$command; exec bash'
echo "Restored backup. It will take a few seconds for the server to be back up."
EOF
    chmod 755 ${mc_script_location}/restore_backup.sh
}

## MAIN
install_pre_req
prepare_ssd
setup_mc_server