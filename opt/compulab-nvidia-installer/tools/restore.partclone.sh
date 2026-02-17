#!/bin/bash

tools_dir=$(readlink -e $(dirname ${BASH_SOURCE[0]}))

[[ -z ${debug:-""} ]] || set -x
[[ $(id -u) -eq 0 ]] || exit -13

[[ -n ${device:-""} ]] || exit 2
[[ -b ${device:-""} ]] || exit 3

source ${tools_dir}/restore.partclone.inc

src=${src} device=${device} apply_layout_func
src=${src} device=${device} restore_partclone_func
