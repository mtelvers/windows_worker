#!/bin/bash
cd ~/windows_worker || exit 1
export PYTHONUNBUFFERED=1
exec stdbuf -oL -eL ansible-playbook playbook.yml \
  -e winver=2025 -e qemu_mem=32G \
  -e uefi=true \
  -e c_partition_mb=5242880 \
  -e '{"vms":[{"name":"ltsc2025-4","disk":"/dev/sdd","winrm_port":5986,"ssh_port":60023,"vnc_display":1,"numa_node":1}]}'
