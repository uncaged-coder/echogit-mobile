#!/data/data/com.termux/files/usr/bin/bash

set -e

echo "arguments=$@"
source source.sh
python3 ${ECHOGIT_PATH}/echogit.py $@
