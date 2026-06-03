#!/bin/bash

# Start Windows QEMU VMs
# Usage: sudo ./run.sh

set -e

MEM=64G
SMP=16

start_vm() {
    local name=$1 disk=$2 winrm_port=$3 ssh_port=$4 vnc_display=$5

    if pgrep -f "qemu-system.*${disk}" >/dev/null 2>&1; then
        echo "${name}: already running"
        return
    fi

    echo "${name}: starting (disk=${disk} winrm=${winrm_port} ssh=${ssh_port} vnc=:${vnc_display})"
    echo numactl --cpunodebind=1 --membind=1 qemu-system-x86_64 \
        -m ${MEM} -smp ${SMP} \
        -machine accel=kvm,type=q35 -cpu host \
        -display none -vnc :${vnc_display} \
        -netdev user,id=net0,hostfwd=tcp::${winrm_port}-:5985,hostfwd=tcp::${ssh_port}-:22 \
        -device virtio-net,netdev=net0 \
        -drive file=${disk},format=raw,if=virtio
    nohup sudo numactl --cpunodebind=1 --membind=1 qemu-system-x86_64 \
        -m ${MEM} -smp ${SMP} \
        -machine accel=kvm,type=q35 -cpu host \
        -display none -vnc :${vnc_display} \
        -netdev user,id=net0,hostfwd=tcp::${winrm_port}-:5985,hostfwd=tcp::${ssh_port}-:22 \
        -device virtio-net,netdev=net0 \
        -drive file=${disk},format=raw,if=virtio \
        </dev/null >/dev/null 2>&1 &
}

start_vm ltsc2025-3 /dev/sdc 5985 60022 0
#start_vm ltsc2025-1 /dev/sdc 5985 60022 0
#start_vm ltsc2025-2 /dev/sdd 5986 60023 1
