#!/bin/bash

function build () {

	rm "${1}.COM" 2>&1 >/dev/null
	nasm "${1}.ASM" -ILIBS/ -fbin -O9 -o "${1}.COM" || exit 1
	if [ ! -f  "${1}.COM" ] ; then
		exit 1
	fi;
	if [ ! -d ../../BIN ] ; then
		mkdir ../../BIN || exit 1
	fi
	if [ -f "../../BIN/${1}.COM" ] ; then
		ls -al "../../BIN/${1}.COM"
	fi
	cp "${1}.COM" "../../BIN/${1}.COM"
	ls -al "../../BIN/${1}.COM"
}

build FDIMPLES