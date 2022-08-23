#!/bin/bash

function die () {

	local ret=$?
	echo "ERROR: compile ${1} failed."
	exit $ret

}

function build () {

	echo "Compile ${1}......"
	[[ -f "${1}.COM" ]] && rm "${1}.COM"
	nasm "${1}.ASM" -ILIBS/ -fbin -O9 -o "${1}.COM" || die "${1}"
	if [ ! -f  "${1}.COM" ] ; then
		die "${1}"
	fi;
	if [ ! -d ../../BIN ] ; then
		mkdir ../../BIN || die "${1}"
	fi
	if [ -f "../../BIN/${1}.COM" ] ; then
		ls -al "../../BIN/${1}.COM"
	fi
	cp "${1}.COM" "../../BIN/${1}.COM"
	ls -al "../../BIN/${1}.COM"
}

function main () {

	local i
	for i in *.ASM ; do
		build "${i%.*}"
	done
}

if [[ $# -eq 0 ]] ; then
	main
else
   while [[ "${1}" != "" ]] ; do
   	build "${1%.*}"
   	shift
   done
fi