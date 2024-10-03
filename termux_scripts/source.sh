#!/data/data/com.termux/files/usr/bin/bash

# Check if running in Termux
if [[ -d "/data/data/com.termux/files/usr/bin" ]]; then
	# Termux-specific setup
	ECHOGIT_PATH=/data/data/com.termux/files/home/data/desk/echogit/
	source ${ECHOGIT_PATH}/.venv/bin/activate
else
	# Linux-specific setup
	ECHOGIT_PATH=/zdata/data/desk/echogit/
fi
