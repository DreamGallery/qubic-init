#!/bin/bash

#Usage ./update.sh $qli-version

if [[ -n "$1" ]]; then
    version="$1"
    echo "update to version $version"
else
    echo "Please input the version"
    exit 1
fi

pkill -f "qli-runner"
supervisorctl stop myprogram

sudo -u qubic bash <<EOF
  cd && wget https://dl.qubic.li/downloads/qli-Client-$version-Linux-x64.tar.gz -O qli-Client-Linux-x64.tar.gz
  cp qcli/appsettings.json appsettings.json
  rm -rf qcli/*
  tar -xzf qli-Client-Linux-x64.tar.gz -C qcli
  mv appsettings.json qcli/appsettings.json
  rm qli-Client-Linux-x64.tar.gz
EOF

supervisorctl start myprogram
tail -f /var/log/qli.out.log
