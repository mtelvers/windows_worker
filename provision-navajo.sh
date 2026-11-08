#!/bin/bash
# navajo: one day10 worker on the whole 1.6T NVMe, UEFI/GPT with C: 256 GiB
# for Windows and containerd and D: (~1.2 TiB) for the day10 cache and the
# worker state. The host is 2x EPYC 7551 (64 threads a socket) with 512G;
# the guest takes half a socket and 200G of node 0's ~256G. Its second NIC
# is on br0, the host bridge over eno2np1 (see /etc/netplan on navajo).
cd ~/windows_worker || exit 1
export PYTHONUNBUFFERED=1
exec stdbuf -oL -eL ansible-playbook playbook.yml \
  -e winver=2025 -e qemu_mem=200G -e qemu_smp=32 \
  -e uefi=true \
  -e worker_kind=day10 \
  -e day10_src_tgz=day10-99de163.tgz \
  -e c_partition_mb=262144 \
  -e '{"vms":[{"name":"ltsc2025-day10","disk":"/dev/nvme0n1","winrm_port":5985,"ssh_port":60022,"vnc_display":0,"numa_node":0,"bridge":"br0","bridge_mac":"52:54:00:e8:22:c7","hyperv":true}]}'
