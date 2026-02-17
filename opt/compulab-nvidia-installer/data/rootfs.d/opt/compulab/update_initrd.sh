#!/bin/bash -x

initrd_file=$(readlink -e /boot/compulab/initrd*)
short_name=$(basename ${initrd_file})
version=${short_name//initrd-/}
odir=$(mktemp --directory)

update-initramfs -u -k ${version} -b ${odir}

cp -v ${odir}/* ${initrd_file}

rm -rf ${odir}
