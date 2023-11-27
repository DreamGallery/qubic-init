#!/bin/bash

if [[ -n "$1" ]]; then
    threads="$1"
else
    echo "please input the threads"
    exit 1
fi

sudo DEBIAN_FRONTEND=noninteractive apt install jq -y

qubic_folder="/home/qubic/qcli"
if [[ -e $qubic_folder ]]; then
jq --arg threads "$threads" \
    '.Settings.amountOfThreads = $threads' \
    /home/qubic/qcli/appsettings.json > tmp && mv tmp /home/qubic/qcli/appsettings.json
else
jq --arg threads "$threads" \
    '.Settings.amountOfThreads = $threads' \
    /root/qcli/appsettings.json > tmp && mv tmp /root/qcli/appsettings.json
fi

sudo systemctl restart qli.service
sudo journalctl -u qli.service -f
