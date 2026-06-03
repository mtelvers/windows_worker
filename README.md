# windows_worker

Ansible playbooks for provisioning the OCluster **`windows-x86_64`** Windows
worker pool. Each worker is a Windows Server 2025 VM running under QEMU/KVM that
builds and runs `ocluster-worker` natively (opam/dune, no Cygwin) with an
OBuilder HCS store.

There is no Vagrant any more — the `qemu` role creates, installs and boots the
VMs directly, then registers them with Ansible in-memory.

## Prerequisites

On the KVM host:

- `qemu-system-x86_64` + KVM, and `numactl`
- `ansible` with the `pywinrm` Python module (WinRM connection plugin)
- `mkisofs` (or `genisoimage`) to build the unattended-install ISO

Files that must be present in the repo directory (all git-ignored):

- The Windows Server install ISO, named to match `iso_names[winver]` in
  `roles/qemu/defaults/main.yml` (e.g.
  `SW_DVD9_Win_Server_STD_CORE_2025_24H2.7_64Bit_English_DC_STD_MLF_X24-06125.ISO`).
  Download it manually — it is ~6.5 GB and not versioned.
- `secrets/pool-windows-x86_64.cap` — the pool capability file (the `secrets/`
  directory is git-ignored).

The virtio-win driver ISO is downloaded automatically by the `qemu` role.

## VM definitions

The VMs to create are listed in `roles/qemu/defaults/main.yml`:

```yaml
vms:
  - name: ltsc2025-1
    disk: /dev/sdc        # raw block device the VM is installed onto (wiped!)
    winrm_port: 5985      # forwarded on the host -> guest 5985
    ssh_port: 60022       # forwarded on the host -> guest 22
    vnc_display: 0
```

Add entries to provision more workers. `winver`, `qemu_mem` and `qemu_smp` are
also defined there.

## Provision

```sh
make provision              # Windows Server 2025 (default)
make provision WINVER=2019  # or 2022 / 2025
```

`make provision` runs `ansible-playbook playbook.yml -e winver=$(WINVER)`, which:

1. **`qemu` role (localhost):** downloads virtio drivers, templates
   `autounattend.xml` into `unattend.iso`, performs an unattended Windows
   install onto each VM's disk, boots the VM with WinRM/SSH port-forwards, waits
   for WinRM, and adds each VM to the in-memory `workers` group.
2. **worker roles (`workers`):** `windows`, `docker`, `containerd`, `git`,
   `opam`, `capnproto`, `hcn-namespace`, `worker` — these build
   `ocluster-worker` at `C:\ocluster` and install it as a Windows service named
   after the host.

Because the inventory is built in-memory, the static `hosts` file only contains
the `[workers]` group header — there is nothing to edit per run.

```sh
make clean    # remove generated unattend.iso / autounattend.xml / install markers
```

## Ad-hoc operations

Small playbooks for day-to-day operations (run against the `hosts` inventory):

```sh
ansible-playbook reboot.yml           # reboot all workers
ansible-playbook shutdown.yml         # shut all workers down
ansible-playbook windows-updates.yml  # install Windows Updates, rebooting as needed
```

`run.sh` is a standalone helper to (re)launch a VM with the right QEMU flags
without re-running the full playbook.

## Connection details

Workers are reached over WinRM (HTTP) as `administrator` / `vagrant` — see
`group_vars/workers`.
