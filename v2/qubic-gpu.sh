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
            echo "Internal error! Use -h/--help for more details"
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

echo "Script used args: [--token $token --alias $alias --threads $threads --version $version --baseUrl $baseUrl]"


sed -i 's/focal/jammy/g' /etc/apt/sources.list
sed -i 's/focal/jammy/g' /etc/apt/sources.list.d/*.list
apt update
DEBIAN_FRONTEND=noninteractive apt -yq upgrade
DEBIAN_FRONTEND=noninteractive apt -yq dist-upgrade
DEBIAN_FRONTEND=noninteractive apt install --yes sudo wine supervisor vim jq

useradd -m -s /bin/bash qubic
echo "qubic ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/custom

sudo -u qubic bash <<ENDOFMESSAGE
cd && wget https://dl.qubic.li/downloads/qli-Client-$version-Linux-x64.tar.gz -O qli-Client-Linux-x64.tar.gz
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
