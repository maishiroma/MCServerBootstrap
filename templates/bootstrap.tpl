#!/bin/bash
set -e
set -x

# This will run during initial launch and relaunches of the instance (i.e. when it is destroyed)
# All variables in here are interpolated into Terraform

## Global Vars
JAR_NAME="server.jar"

prepare_ssd() {
    mkdir ${mc_home_folder}
    mkfs -t ext4 /dev/sdb
    mount -t ext4 /dev/sdb ${mc_home_folder}
}

install_pre_req() {
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

    apt-get update
    apt-get install -y gsutil
    apt-get install -y default-jre-headless zip screen google-cloud-sdk
}

setup_mc_server() {
    cd ${mc_home_folder}
    wget -O $JAR_NAME ${mc_server_download_link}

    set +e
    java -Xms${server_min_ram} -Xmx${server_max_ram} -jar $JAR_NAME nogui
    set -e

    sed -i 's/eula=false/eula=true/g' eula.txt
    touch eula.txt

    screen -dm -S mcs /bin/bash -c 'java -Xms${server_min_ram} -Xmx${server_max_ram} -jar $JAR_NAME nogui; exec /bin/bash'
}

configure_backups() {
    cd ${mc_home_folder}

    cat << EOF > ./backup.sh
#!/bin/bash
screen -r mcs -X stuff '/save-all\n/save-off\n'
/usr/bin/zip -r -q backup.zip ${mc_home_folder}/world
/usr/bin/gsutil cp -R ${mc_home_folder}/backup.zip gs://${backup_bucket}/\$(date "+%Y%m%d-%H%M%S")-world
rm -f backup.zip
screen -r mcs -X stuff '/save-on\n'
EOF

    chmod 755 ./backup.sh
}

configure_restart() {
    cd ${mc_home_folder}

    cat << EOF > ./restart.sh
#!/bin/bash
mount -t ext4 /dev/sdb ${mc_home_folder}
screen -dm -S mcs /bin/bash -c 'java -Xms${server_min_ram} -Xmx${server_max_ram} -jar $JAR_NAME nogui; exec /bin/bash'
EOF

    chmod 755 ./restart.sh
}

configure_restore_backup() {
     cd ${mc_home_folder}

     cat << EOF > ./restore_backup.sh
#!/bin/bash
screen -r -X stuff '/stop\\n'
mv world/ world_old/
/usr/bin/gsutil cp gs://${backup_bucket}/\$1 backup.zip
mkdir world
/usr/bin/unzip -q backup.zip -d world/
sleep 30
screen -dm -S mcs /bin/bash -c 'java -Xms${server_min_ram} -Xmx${server_max_ram} -jar $JAR_NAME nogui; exec /bin/bash'
rm -f backup.zip
EOF
}

## Main Execution
install_pre_req
prepare_ssd
setup_mc_server
configure_backups
configure_restart
configure_restore_backup