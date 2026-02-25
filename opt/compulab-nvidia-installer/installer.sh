#!/bin/bash -e

work_dir=$(readlink -e $(dirname ${BASH_SOURCE[0]}))
tools_dir=${work_dir}/tools
src_dir=${work_dir}/data/images.d/01
rootfs_dir=${work_dir}/data/rootfs.d
#
export inst_info=/tmp/install.$(date +%Y_%m_%d-%T | tr  ":" "_")
mkdir -p ${inst_info}
#

source ${work_dir}/installer.log
source ${work_dir}/installer.env
source ${work_dir}/installer.inc
source ${work_dir}/installer.lay
source ${tools_dir}/restore.partclone.inc

installer_update() {
    echo -n "Validating the Internet connection:"
    ping -c 1 8.8.8.8 &>/dev/null && rc=$? || rc=$?
    if [[ ${rc} -ne 0 ]];then
        echo "[ FAILURE ]"
        return 22
    fi
    echo "[ OKAY ]"
    source ${work_dir}/installer.upd
    echo "The Installer has been updated."
}
installer_update

choose_device_func() {
    local select_string=$(get_install_devices)" Exit"
    PS3="Choose device > "
    local _device=""
    while [ -z ${_device:-""} ];do
        select j in ${select_string}; do
            case ${j} in
                "Exit")
                exit 0
                ;;
                *)
                export device=${j}
                return 0
                ;;
            esac
        done
    done
}

installer_probe_func() {
    if [ -z ${device:-""} ];then
        choose_device_func ; return $?

    fi
    if [ ! -b ${device:-""} ];then
        choose_device_func ; return $?
    fi
    local root_device=$(get_root_device)
    if [ ${device} = ${root_device} ];then
cat << eof
    WARNING: Target device is the current root device ${device} please choose another one ..."
eof
        choose_device_func ; return $?
    fi
}


installer_func() {
    local select_string=""
    local layout=""
    local encrypt=""

    for _layout in $(for __layout in ${!layout_array[@]};do echo ${__layout}; done | sort -u);do
        layout_id=${_layout}
        layout_string=$(sed "s/ /__/g" <<< ${layout_array[${_layout}]})
        select_string+="${layout_id}--[${layout_string}]  "
    done
    select_string+=" Exit"
    PS3="Choose layout > "
    while [ -z ${layout:-""} ];do
        select j in ${select_string}; do
            case ${j} in
                "Exit")
                exit 0
                ;;
                *)
                layout=${j}
                break
                ;;
            esac
        done
    done

    select_string="Yes No Exit"
    PS3="Issue encryption > "
    while [ -z ${encrypt:-""} ];do
        select j in ${select_string}; do
            case ${j} in
                "Exit")
                exit 0
                ;;
                *)
                encrypt=${j}
                break
                ;;
            esac
        done
    done

    [[ ${encrypt} = "Yes" ]] && source ${work_dir}/installer.enc
    # Get the layout func from the select string
    layout=(${layout/--/ })
    layout=${layout[0]}

    ${layout}

	[[ ${_APP_SIZE} -eq 0 ]] && rootfs_szie="To the end of the media" || rootfs_szie="${_APP_SIZE}GB"
cat << eof | tee ${inst_info}/inst.manifest
	Installation parameters:
	-
		Device: ${device}
		Layout: ${layout}
		Encryption: ${encrypt}
		Rootfs size: ${rootfs_szie}
	-
eof
read -p "Press any key to continue; Crtl^C to exit ...."

    inst_init
    src=${src_dir} device=${device} apply_layout_func
    [[ ${encrypt} = "Yes" ]] && system_enc_init
    src=${src_dir} device=${device} restore_partclone_func
    [[ ${encrypt} = "Yes" ]] && system_enc_fini
    inst_fini

    [[ $? -eq 0 ]] && figlet "Done: OKAY" || figlet "Failed"
}

installer_probe_func
cat << eof
Starting install onto the ${device} ...
eof
installer_func
