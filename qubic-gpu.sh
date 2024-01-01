#!/bin/bash

echo "Usage ./qubic-gpu.sh token [alias] [threads/gpu_num] [version|dafault 1.8.0|qli-Cilent url] [diyschool|qubic|default baseUrl:"https://mine.qubic.li"]"
echo "if you want to change the default baseUrl, diyschool for https://ai.diyschool.ch, qubic for https://mine.qubic.li"
echo "Example ./qubic-gpu.sh token alias threads 1.8.0 diyschool. 5 args needed."
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
    echo "Using Default alias qli_Client_GPU"
    alias="qli_Client_GPU"
fi
if [[ -n "$3" ]]; then
    threads="$3"
    echo "Set threads to $threads"
else
    echo "Using Default training threads 1"
    threads="1"
fi
if [[ -n "$4" ]]; then
    if [[ -n $(echo $4| grep "http") ]]; then
        url="$4"
    else
        version="$4"
        url="https://dl.qubic.li/downloads/qli-Client-$version-Linux-x64.tar.gz"
        echo "Using qli-Client version $version"
    fi
else
    echo "Using Default qli-Client version 1.8.0"
    version="1.8.0"
    url="https://dl.qubic.li/downloads/qli-Client-$version-Linux-x64.tar.gz"
fi
if [[ -n "$5" ]]; then
    if [[ $5=="diyschool" ]]; then
        baseUrl="https://ai.diyschool.ch/"
    elif [[ $5=="qubic" ]]; then
        baseUrl="https://mine.qubic.li/"
    else
        echo "invalid baseUrl, please check."
        exit 1
    fi
else
    baseUrl="https://mine.qubic.li/"
fi

sed -i 's/focal/jammy/g' /etc/apt/sources.list
sed -i 's/focal/jammy/g' /etc/apt/sources.list.d/*.list
apt update
DEBIAN_FRONTEND=noninteractive apt -yq upgrade
DEBIAN_FRONTEND=noninteractive apt -yq dist-upgrade
DEBIAN_FRONTEND=noninteractive apt install --yes sudo wine supervisor vim jq

useradd -m -s /bin/bash qubic
echo "qubic ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/custom

sudo -u qubic bash <<ENDOFMESSAGE
cd && wget $url -O qli-Client-Linux-x64.tar.gz
[[ -d qcli ]] || mkdir qcli
tar -xzf qli-Client-Linux-x64.tar.gz -C qcli
rm qli-Client-Linux-x64.tar.gz
echo "./qli-Client" > qcli/qli-Service.sh
chmod +x qcli/qli-Service.sh

jq --arg threads "$threads" \
    --arg baseUrl "$baseUrl" \
    --arg token "$token" \
    --arg alias "$alias" \
    '.Settings.baseUrl = "$baseUrl"| .Settings.amountOfThreads = "$threads" | .Settings.accessToken = "$token" | .Settings.alias = "$alias" | .Settings.allowHwInfoCollect = true | .Settings."overwrites" = {"CUDA": "12"}' \
    qcli/appsettings.json > tmp.json && mv tmp.json qcli/appsettings.json

sudo tee /etc/supervisor/conf.d/qubic.conf > /dev/null <<EOF
[program:myprogram]
command=/home/qubic/qcli/qli-Client
autostart=true
autorestart=true
stderr_logfile=/var/log/qli.err.log
stdout_logfile=/var/log/qli.out.log
user=qubic
directory=/home/qubic/qcli
EOF

ENDOFMESSAGE

supervisord -c /etc/supervisor/supervisord.conf
sleep 10
tail -f /var/log/qli.out.log
