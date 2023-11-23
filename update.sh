#!/bin/bash

#Usage ./update.sh $qli-version

if [[ -n "$1" ]]; then
    version="$1"
    echo "update to version $version"
else
    echo "Please input the version"
    exit 1
fi

sudo systemctl stop qli.service

sudo -u qubic bash <<EOF
cd && wget https://dl.qubic.li/downloads/qli-Client-$version-Linux-x64.tar.gz
cp qcli/appsettings.json appsettings.json
cp qcli/qli-Service.sh qli-Service.sh
rm -rf qcli/*
tar -xzf qli-Client-$version-Linux-x64.tar.gz -C qcli
mv appsettings.json qcli/appsettings.json
mv qli-Service.sh qcli/qli-Service.sh
rm qli-Client-$version-Linux-x64.tar.gz
EOF

sudo systemctl start qli.service
sudo journalctl -u qli.service -f
