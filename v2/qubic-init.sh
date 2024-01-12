#!/bin/bash

args_list=(token alias threads version baseUrl)
default_list=(qli_Client_GPU 1 1.8.3 https://mine.qubic.li/)

ARGS=`getopt -o t:h --long token:,alias:,threads:,version:,baseUrl:,help -n "$0" -- "$@"`
if [ $? != 0 ]; then
    echo "Terminating..."
    exit 1
fi

eval set -- "${ARGS}"

while true
do
    case "$1" in
        -t|--token)
            token="$2"
            echo "Using token $token"
            shift 2
            ;;
        --alias)
            alias="$2"
            echo "Set Alias to $alias"
            shift 2
            ;;
        --threads)
            threads="$2"
            echo "Set threads to $threads"
            shift 2
            ;;
        --version)
            version="$2"
            echo "Using qli-Client version $version";
            shift 2
            ;;
        --baseUrl)
            if [[ $2 == "diyschool" ]]; then
                baseUrl="https://ai.diyschool.ch/"
            else
                echo "invalid argument."
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./qubic-gpu.sh -t|--token access_token [--alias alias] [--threads threads] [-v|--version version] [baseUrl qubic|diyschool]"
            echo "-t, --token       access token                                                                        required"
            echo "--alias           miner alias                                                                         optional"
            echo "--threads         mining threads, default thread 1                                                    optional"
            echo "-v, --version     qli-Cilent version, default version 1.8.3                                           optional"
            echo "--baseUrl         set diyschool for https://ai.diyschool.ch/, default https://mine.qubic.li/          optional"
            shift
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Internal error!"
            exit 1
            ;;
    esac
done

arg_index=0
for args_name in ${args_list[@]}; do
    if [[ $args_name == "token" ]]; then
        if [[ ! -n "$(eval echo \$$args_name)" ]]; then
            echo "Access token is required."
            exit 1
        fi
    else
        if [[ ! -n "$(eval echo \$$args_name)" ]]; then
            eval $args_name=${default_list[$arg_index]}
        fi
        arg_index=$(($arg_index+1))
    fi
done

echo "Script used args: --token $token --alias $alias --threads $threads --version $version --baseUrl $baseUrl"

sudo apt update
echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf
DEBIAN_FRONTEND=noninteractive \
  sudo apt-get \
  -o Dpkg::Options::=--force-confold \
  -o Dpkg::Options::=--force-confdef \
  -y --allow-downgrades --allow-remove-essential --allow-change-held-packages \
  dist-upgrade

DEBIAN_FRONTEND=noninteractive apt install --yes jq

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
