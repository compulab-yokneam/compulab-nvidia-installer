#!/bin/bash

disk_layout_file="disk.layout"

rename_app_partition() {
    local name=$(ls part1.* 2>/dev/null)
    [[ -n ${name:-""} ]] || return 0 # done case
    local newname=${name/part1/part16}
    mv ${name} ${newname}
}

_disk_layout_installer() {
    local ROOT_UUID="uuid=$(uuidgen --sha1 --namespace @dns --name root)"
    local NEW_APP_SIZE=1048576

    eval $(awk '/APP/&&( (gsub(/p1$/,"",$1))  &&($0="ROOT_DEVICE="$1" ROOT_START="$4" APP_SIZE="$6" ROOT_TYPE="$7) && (gsub(/,/,"")))' ${disk_layout_file})
    ROOT_START=$(( ${ROOT_START} + ${NEW_APP_SIZE} ))

    sed "s/${APP_SIZE}/${NEW_APP_SIZE}/" ${disk_layout_file}
cat << eof
${ROOT_DEVICE}p16 : start=     ${ROOT_START}, size=   @@SIZE@@,  ${ROOT_TYPE}, ${ROOT_UUID}, name="root"
eof
}

disk_layout_installer() {
    # Make sure that the layout file requires modifications
    grep -q "@@SIZE@@" ${disk_layout_file} && return 0 || true
    cp ${disk_layout_file} ${disk_layout_file}".in"
    disk_layout_file=${disk_layout_file}".in" _disk_layout_installer > ${disk_layout_file}
}

error_exit() {
    cat << eof
The mandatory ${disk_layout_file} file is not in the ${PWD}
Make sure that the current working directory contains the partclone files and the ${disk_layout_file} file
eof
    exit 22
}

[[ -e ${disk_layout_file} ]] || error_exit
rename_app_partition
disk_layout_file=${disk_layout_file} disk_layout_installer
