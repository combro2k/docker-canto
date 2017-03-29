#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

export DEBIAN_FRONTEND="noninteractive"
export CANTO_NEXT_VERSION="0.9.6"
export CANTO_CLIENT_VERSION="0.9.7"

pre_install() {
	apt-get update
	apt-get install -yq curl || return 1

	if [ ! -d /usr/src/build ]; then
		mkdir -p /usr/src/build/daemon /usr/src/build/client || return 1
	fi

    	return 0
}

install() {
	apt-get install -yq python3 python3-feedparser libncursesw5-dev libreadline6-dev libncurses5-dev python3-dev gcc || return 1

	curl --location https://github.com/themoken/canto-next/archive/v${CANTO_NEXT_VERSION}.tar.gz | tar zxv -C /usr/src/build/daemon --strip-components=1 || return 1
	curl --location https://github.com/themoken/canto-curses/archive/v${CANTO_CLIENT_VERSION}.tar.gz | tar zxv -C /usr/src/build/client --strip-components=1 || return 1

	cd /usr/src/build/daemon && python3 setup.py install --prefix=/usr || return 1
	cd /usr/src/build/client && python3 setup.py install --prefix=/usr || return 1

	return 0
}

post_install() {
	apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt /usr/src/build 2>&1 || return 1

	chmod +x /usr/local/bin/* || return 1

	return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	tasks=(
        'pre_install'
	'install'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..." || exit 1
		${task} | tee -a "${INSTALL_LOG}" || exit 1
	done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1  || exit 1
		${task} || exit 1
	done
fi
