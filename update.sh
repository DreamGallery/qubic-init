#!/bin/bash

#Usage ./update.sh $qli-version

if [[ -n "$1" ]]; then
    version="$1"
    echo "update to version $version"
else
    echo "Please input the version"
    exit 1
fi
if [[ -n "$2" && "$2"=="github" ]]; then
    url="https://github.com/DreamGallery/qubic-init/releases/download/v$version/qli-Client-$version-Linux-x64.tar.gz"
else
    url="https://dl.qubic.li/downloads/qli-Client-$version-Linux-x64.tar.gz"
fi



sudo systemctl stop qli.service

qubic_folder="/home/qubic/qcli"
if [[ -e $qubic_folder ]]; then
    sudo -u qubic bash <<EOF
    cd && wget $url
    cp qcli/appsettings.json appsettings.json
    cp qcli/qli-Service.sh qli-Service.sh
    rm -rf qcli/*
    tar -xzf qli-Client-$version-Linux-x64.tar.gz -C qcli
    mv appsettings.json qcli/appsettings.json
    mv qli-Service.sh qcli/qli-Service.sh
    rm qli-Client-$version-Linux-x64.tar.gz
EOF
else
    cd && wget $url
    cp qcli/appsettings.json appsettings.json
    cp qcli/qli-Service.sh qli-Service.sh
    rm -rf qcli/*
    tar -xzf qli-Client-$version-Linux-x64.tar.gz -C qcli
    mv appsettings.json qcli/appsettings.json
    mv qli-Service.sh qcli/qli-Service.sh
    rm qli-Client-$version-Linux-x64.tar.gz
fi

sudo systemctl start qli.service
sudo journalctl -u qli.service -f
