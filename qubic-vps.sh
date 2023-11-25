#!/bin/bash

if [[ -n "$1" ]]; then
    token="$1"
    echo "Using token $token"
else
    echo "Please input you token"
    exit 1
fi
if [[ -n "$2" ]]; then
    alias="$2"
    echo "Set Alias to $alias"
else
    echo "Using Default alias qli_Client"
    alias="qli_Client"
fi
if [[ -n "$3" ]]; then
    threads="$3"
    echo "Set threads to $threads"
else
    echo "Using Default training threads 2"
    threads="2"
fi
if [[ -n "$4" ]]; then
    version="$4"
    echo "Using qli-Client version $version"
else
    echo "Using Default qli-Client version 1.6.1"
    version="1.6.1"
fi

echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf

sudo apt update && DEBIAN_FRONTEND=noninteractive apt install --yes wine jq

useradd -m -s /bin/bash qubic
echo "qubic ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/custom

sudo -u qubic bash <<ENDOFMESSAGE
cd && wget https://dl.qubic.li/downloads/qli-Client-$version-Linux-x64.tar.gz
mkdir qcli
tar -xzf qli-Client-$version-Linux-x64.tar.gz -C qcli
rm qli-Client-$version-Linux-x64.tar.gz
echo "./qli-Client" > qcli/qli-Service.sh
chmod +x qcli/qli-Service.sh

jq --arg threads "$threads" \
    --arg token "$token" \
    --arg alias "$alias" \
    '.Settings.amountOfThreads = "$threads" | .Settings.accessToken = "$token" | .Settings.alias = "$alias" | .Settings.useAvx2 = "true"' \
    qcli/appsettings.json > tmp.json && mv tmp.json qcli/appsettings.json

sudo tee /etc/systemd/system/qli.service > /dev/null <<EOF
[Unit]
After=network.target
[Service]
User=qubic
StandardOutput=syslog
StandardError=syslog
WorkingDirectory=$(su - qubic -c 'echo $HOME')/qcli
ExecStart=/bin/bash qli-Service.sh
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=default.target
EOF

ENDOFMESSAGE

sudo systemctl daemon-reload
sudo systemctl enable qli.service
sudo systemctl start qli.service
# sudo journalctl -u qli.service -f
