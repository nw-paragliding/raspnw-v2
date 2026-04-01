#!/bin/bash
source $(dirname $0)/output_util.sh
source $(dirname $0)/check_basedir.sh

OS=$(lsb_release -si)

if [[ $OS == "Ubuntu" ]]; then
	echo "Detected Ubuntu OS"
	
	sudo dpkg --add-architecture i386
	if [ $? != 0 ] 
	then
		print_error "sudo dpkg --add-architecture i386"
		exit -1
	fi

	sudo apt-get update
	if [ $? != 0 ] 
	then
		print_error "sudo apt-get update"
		exit -1
	fi
	
	sudo apt-get install -y libc6:i386 libncurses5:i386 libstdc++6:i386
		if [ $? != 0 ] 
	then
		print_error "apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386"
		exit -1
	fi

	# multiarch-support was removed in Ubuntu 16.04+; skip gracefully if unavailable
	sudo apt-get install -y multiarch-support 2>/dev/null || echo "Warning: multiarch-support not available (Ubuntu 16.04+), skipping"
fi
