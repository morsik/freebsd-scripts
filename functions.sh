#!/bin/sh

alias i="info"
alias e="error"
alias p="process"
alias p_end="process_end"
alias echo="echo -e"

info() {
	echo "\033[1;32m >> \033[1;37m$1\033[0m"
}

warn() {
	echo "\033[1;33m !! \033[1;37m$1\033[0m"
}

error() {
	echo "\033[1;31m !! \033[1;37m$1\033[0m"
}

process() {
	echo -n "\033[0G\033[0K    \033[0m$1..."
}

process_end() {
	echo -n "\033[0G\033[0K\033[0m"
}

ifos() {
	if [ `uname -s` != $1 ]
	then
		echo $2
		exit 1
	fi
}
