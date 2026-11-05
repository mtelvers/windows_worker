#!/bin/bash
# c_partition_mb is 6400 GiB, leaving ~1 TiB for D:. ltsc2025-4 was built with
# C: 5 TiB / D: 2.3 TiB, but after a month its Docker volume held 226 GB of a
# bounded 13-image matrix with 0% reclaimable, so 2.3 TiB was never going to be
# used. The space is worth more to the obuilder store on C:.
cd ~/windows_worker || exit 1
export PYTHONUNBUFFERED=1
exec stdbuf -oL -eL ansible-playbook playbook.yml \
  -e winver=2025 -e qemu_mem=80G -e qemu_smp=20 \
  -e uefi=true \
  -e c_partition_mb=6553600 \
  -e '{"vms":[{"name":"ltsc2025-6","disk":"/dev/vg_basil/lv_vm2","winrm_port":5986,"ssh_port":60023,"vnc_display":1,"numa_node":1}]}'
