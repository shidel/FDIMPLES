#!/bin/bash

rm FDIMPLES.COM >/dev/null
nasm "FDIMPLES.ASM" -ILIBS/ -fbin -O9 -o "FDIMPLES.COM" || exit 1
if [ ! -f FDIMPLES.COM ] ; then
	exit 1
fi;
if [ ! -d ../../BIN ] ; then
	mkdir ../../BIN || exit 1
fi
if [ -f ../../BIN/FDIMPLES.COM ] ; then
	ls -al ../../BIN/FDIMPLES.COM
fi
cp FDIMPLES.COM ../../BIN/FDIMPLES.COM
ls -al ../../BIN/FDIMPLES.COM

