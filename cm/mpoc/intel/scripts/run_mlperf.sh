#!/bin/bash

CONFIG_FILE="${1}"

source setup_envs.sh

echo -e "\e[0;34m Config file: ${CONFIG_FILE} \e[0m"

if [ ${CONFIG_FILE} == "" ]; then
	echo " No config file provided. Using default configuration"
	python3 main.py
else

	if [ -e ${CONFIG_FILE} ]; then
		python3 main.py -c ${CONFIG_FILE}
	else
		echo " Unable to find config file ${CONFIG_FILE} "
		exit
	
	fi

fi

