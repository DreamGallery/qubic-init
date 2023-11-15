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
    echo "Using Default training threads 16"
    threads="16"
fi

sudo apt update
echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
DEBIAN_FRONTEND=noninteractive \
  sudo apt-get \
  -o Dpkg::Options::=--force-confold \
  -o Dpkg::Options::=--force-confdef \
  -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  dist-upgrade

sudo apt update && DEBIAN_FRONTEND=noninteractive apt install --yes wine jq

useradd -m -s /bin/bash qubic
echo "qubic ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/custom

sudo -u qubic bash <<ENDOFMESSAGE
cd && wget https://github.com/DreamGallery/qubic-init/releases/download/v1.5.9/qli-Cilent.tar.gz
mkdir qcli_b
tar -xzf qli-Cilent.tar.gz -C qcli_b
mv qcli_b/qli-Cilent/* qcli_b/
rm -rf qcli_b/qli-Cilent && rm qli-Cilent.tar.gz
chmod +x qcli/qli-Service.sh

jq --arg threads "$threads" \
    --arg token "$token" \
    --arg alias "$alias" \
    '.Settings.amountOfThreads = "$threads" | .Settings.accessToken = "$token" | .Settings.alias = "$alias"' \
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
sudo journalctl -u qli.service -f
