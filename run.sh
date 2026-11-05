#!/bin/bash

# Start Windows QEMU VMs
# Usage: sudo ./run.sh
#
# Both VMs run on NUMA node 1: 20 logical CPUs (10-19,30-39), 96757 MB.
# 10 vCPUs each is exactly the node's worth.
#
# Memory is --preferred=1, NOT --membind=1. membind is a hard wall: when
# node 1 is full the kernel OOM-kills rather than spill, and it cannot
# migrate other processes' anonymous pages off the node to make room. That
# killed a VM three times on 2026-10-28, the last at 35G of its 40G.
#
# cpunodebind only restricts THESE processes to node 1's cores; it does not
# reserve them. Other host tasks are still scheduled there and, by
# first-touch policy, take node 1 memory - 23G of it at one point. preferred
# keeps the VMs node-local when there is room and degrades to cross-node
# latency when there is not, instead of dying.
#
# cache=none gives the guest O_DIRECT access to its disk so the host stops
# shadowing, in its own page cache, every block the guest already caches.

set -e

MEM=40G
SMP=10
NODE=1

HERE="$(cd "$(dirname "$0")" && pwd)"

start_vm() {
    local name=$1 disk=$2 winrm_port=$3 ssh_port=$4 vnc_display=$5 ovmf_vars=$6

    if pgrep -f "qemu-system.*${disk}" >/dev/null 2>&1; then
        echo "${name}: already running"
        return
    fi

    local pflash=()
    if [ -n "${ovmf_vars}" ]; then
        pflash=(-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd
                -drive if=pflash,format=raw,file="${ovmf_vars}")
    fi

    echo "${name}: starting (disk=${disk} winrm=${winrm_port} ssh=${ssh_port}" \
         "vnc=:${vnc_display} node=${NODE} mem=${MEM} smp=${SMP})"
    nohup sudo numactl --cpunodebind=${NODE} --preferred=${NODE} qemu-system-x86_64 \
        -m ${MEM} -smp ${SMP} \
        -machine accel=kvm,type=q35 -cpu host \
        "${pflash[@]}" \
        -display none -vnc :${vnc_display} \
        -netdev user,id=net0,hostfwd=tcp::${winrm_port}-:5985,hostfwd=tcp::${ssh_port}-:22 \
        -device virtio-net,netdev=net0 \
        -drive file=${disk},format=raw,if=virtio,cache=none \
        </dev/null >/dev/null 2>&1 &
}

start_vm ltsc2025-3 /dev/sdc 5985 60022 0
start_vm ltsc2025-4 /dev/sdd 5986 60023 1 "${HERE}/OVMF_VARS-ltsc2025-4.fd"
