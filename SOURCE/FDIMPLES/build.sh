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

function build_tests () {

	local i x
	for i in DEVTESTS/*.ASM ; do
		[[ ! -e "${i}" ]] && continue
		x="${i##*/}"
		x="${x%%.*}"
		x="${x//TEST}"
		[[ ${x} -lt 7 ]] && continue
		build "${i}"
	done
}

function wct () {

	local t=$(wc ${@} FDIMPLES.ASM LIBS/*.INC LIBS/*/*.INC 2>/dev/null | grep -i ' total')
	echo ${t% *}
}

function build_main () {


	local i
	for i in *.ASM ; do
		[[ ! -e "${i}" ]] && continue
		build "${i}"
	done

	echo "$(wct -l) lines of source code ($(( $(wct -c) / 1024 )) kbytes)"
}

if [[ $# -eq 0 ]] ; then
	build_tests  # when libs are more complete, won't build automatically
	build_main
else
   while [[ "${1}" != "" ]] ; do
   	build "${1%.*}"
   	shift
   done
fi