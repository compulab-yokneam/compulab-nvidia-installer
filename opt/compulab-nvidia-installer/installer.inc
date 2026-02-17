wait() {
    cnt=${1:-3}
    while  [ $(( cnt-- )) -ne 0 ];do echo -n ${cnt}" "; sleep 1; done
}

get_partition_by_name() {
    [[ -n ${1:-""} ]] || return 22
    blkid ${device}* | awk -v name=${1} -F":" '{ if ($0 ~ name) { print $1 } }'
}

# expand partition, but not its contant
# there can be a non-filesystem stuff
expand_partition() {
    local part=${part:-""}

    [[ -n ${part:-""} ]] || return 22
    [[ -b ${part:-""} ]] || return 22

    local disk=$(part=${part} get_disk_by_partition)
    local number=$(cat /sys/class/block/$(basename ${part})/partition)
    parted -s ${disk} resizepart ${number} 100%
    wait 1
    return 0
}

get_disk_by_partition() {
    local part=${part:-""}

    [[ -n ${part:-""} ]] || return 22
    [[ -b ${part:-""} ]] || return 22

    eval $(udevadm info -x --query=property ${part})

    while [ 1 ];do
        unset DEVTYPE DEVNAME
        eval $(udevadm info -x --query=property /sys/${DEVPATH} | awk '/DEVPATH|DEVTYPE|DEVNAME/')
        [[ -n ${DEVTYPE:-""} ]] || return 22
        [[ ${DEVTYPE} = 'disk' ]] && break
        DEVPATH=$(dirname ${DEVPATH})
    done

    echo -n ${DEVNAME}
    return 0
}

get_root_device() {
    root_part=$(findmnt / --output SOURCE --noheadings)

    local disk=$(part=${root_part} get_disk_by_partition)

    echo -n ${disk}
}

get_block_devices() {
    declare -A block_devices=()
    for _block in /sys/class/block/*;do
        local disk=$(part=/dev/$(basename ${_block}) get_disk_by_partition)
        block_devices[${disk}]+=${_block}" "
    done
    echo ${!block_devices[@]}
}

# 128GiB in block
min_mdeia_size=$(( 64  << $(( 30 - 9 )) ))

get_install_devices() {
    local install_devs=""
    local block_dev=$(get_block_devices)
    local root_dev=$(get_root_device)
    block_dev=${block_dev/${root_dev}/ }
    for _block in ${block_dev};do
        local _size=$(cat /sys/class/block/$(basename ${_block})/size)
        [[ ${_size} -gt ${min_mdeia_size} ]] &&install_devs+=${_block}" "
    done
    echo ${install_devs}
}

issue_chroot() {
    [[ -n ${rootfs_mpoint:-""} ]] || return 22
    [[ -d ${rootfs_mpoint:-""} ]] || return 22
    chroot_cmd=${chroot_cmd:-""}
    mount -B /dev ${rootfs_mpoint}/dev/
    mount -B /dev/pts ${rootfs_mpoint}/dev/pts
    mount -B /sys ${rootfs_mpoint}/sys
    mount -B /proc ${rootfs_mpoint}/proc
    mount -B /etc/resolv.conf ${rootfs_mpoint}/etc/resolv.conf
    chroot ${rootfs_mpoint} "${chroot_cmd}"
    umount ${rootfs_mpoint}/etc/resolv.conf ${rootfs_mpoint}/proc ${rootfs_mpoint}/sys ${rootfs_mpoint}/dev/pts ${rootfs_mpoint}/dev
}

open_close_device() {

    command -v ${sys_call}_enc_volume >/dev/null || {
        echo ${device}
        return 0
    }

    unset TYPE PARTLABEL
    eval $(blkid ${device} | awk -F":" '$0=$2')
    if [[ ${TYPE} = "crypto_LUKS" ]];then
        part_name=${PARTLABEL} ${sys_call}_enc_volume && rc=$? || rc=$?
        if [[ ${rc} -eq 0 ]];then
            echo "/dev/mapper/${PARTLABEL}"
            return 0
        fi
        return 22
    fi
    echo ${device}
    return 0
}

open_device() {
    local device_name=$(device=${device} sys_call="open" open_close_device)
    echo ${device_name}
    return 0
}

close_device() {
    local device_name=$(device=${device} sys_call="close" open_close_device)
    return 0
}
