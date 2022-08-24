#!/bin/bash

function die () {

	local ret=$?
	echo "ERROR: compile ${1} failed."
	exit $ret

}

function build () {

	local s="${1}"
	local n="${s##*/}"
	n="${n%.*}"
	local o="${n}.COM"
	echo "Compile ${n}......"
	[[ -f "${o}" ]] && rm "${o}"
	nasm "${s}" -ILIBS/ -fbin -O9 -o "${o}" || die "${n}"
	if [ ! -f  "${o}" ] ; then
		die "${n}"
	fi;
	if [ ! -d ../../BIN ] ; then
		mkdir ../../BIN || die "${n}"
	fi
	if [ -f "../../BIN/${o}" ] ; then
		ls -al "../../BIN/${o}"
	fi
	cp "${o}" "../../BIN/${o}"
	ls -al "../../BIN/${o}"
}

function main () {

	local i
	for i in DEVTESTS/*.ASM ; do
		[[ ! -e "${i}" ]] && continue
		build "${i}"
	done
	for i in *.ASM ; do
		[[ ! -e "${i}" ]] && continue
		build "${i}"
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