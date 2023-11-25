#!/bin/bash

systemctl stop qli
systemctl disable qli
deluser qubic
rm -rf /home/qubic
rm -f /etc/systemd/system/qli.service
