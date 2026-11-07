# windows_worker

Ansible playbooks and configs for the OCluster Windows worker pool (`windows-x86_64`).

## Host layout

| Worker | SSH alias | Host | Notes |
|--------|-----------|------|-------|
| `ltsc2025-1` | `ssh ltsc2025-1` | `thyme.caelum.ci.dev:60022` | QEMU VM on thyme |
| `ltsc2025-2` | `ssh ltsc2025-2` | `thyme.caelum.ci.dev:60023` | QEMU VM on thyme |
| `ltsc2025-3` | `ssh ltsc2025-3` | `127.0.0.1:60022` | QEMU VM on this machine |
| `ltsc2025-4` | | `mint.caelum.ci.dev:60023` | QEMU VM on mint |
| `ltsc2025-5`, `ltsc2025-6` | | `basil.caelum.ci.dev:60022/60023` | QEMU VMs on basil |
| `ltsc2025-day10` | | `navajo.caelum.ci.dev:60022` | QEMU VM on navajo; pool `day10-windows-x86_64`, not `windows-x86_64`; registers and runs its service as `navajo` (`worker_name` in host_vars) |

SSH aliases live in `~/.ssh/config`. All workers run Windows Server 2025.

## Per-worker layout (inside the Windows VM)

- Worker source: `C:\ocluster` (native opam/dune build, no Cygwin — see `roles/worker/tasks/main.yml`)
- State dir: `C:\state` — `worker-<pid>.log` per worker run; current run = newest file
- OBuilder store: `C:\obuilder` (HCS backend via containerd)
- Service name: lowercase `inventory_hostname_short` (e.g. `ltsc2025-3`)
- Capability file: `C:\windows\pool-windows-x86_64.cap`
- Manual start script: `C:\windows\go.bat`

day10 workers (`worker_kind=day10`, see `provision-navajo.sh`) differ: no
Docker; `C:\day10` (tool, installed as `C:\windows\system32\day10.exe`);
`C:\ocluster` is the `day10` branch of mtelvers/ocluster; state in
`D:\ocluster-state` (worker logs, opam-repository mirror under `git\`); the
layer cache in `D:\cache`; capability `C:\windows\pool-day10-windows-x86_64.cap`.
The service runs as `.\Administrator`, not LocalSystem, and the roles
apply three patches on top of the pinned day10/ocluster sources (see
`roles/day10/files` and `roles/day10-worker/files`); without them day10 does
not work under a service at all. day10's stderr is in the worker log.
Inspect with `ocluster-admin -c ~/admin.cap show day10-windows-x86_64` and
test with `ocluster-client submit-day10 -c ~/mtelvers.cap --pool day10-windows-x86_64 ...`.

## Common operations

```sh
# Pool view (ci3-admin is an alias for `ocluster-admin -c ~/admin.cap`)
ci3-admin show windows-x86_64
ci3-admin show windows-x86_64 ltsc2025-3   # single worker

# Service control on the VM
ssh ltsc2025-3 'sc query ltsc2025-3'
ssh ltsc2025-3 'sc start ltsc2025-3'
ssh ltsc2025-3 'sc stop ltsc2025-3'

# Latest log on a worker
ssh ltsc2025-3 'powershell -Command "Get-Content (Get-ChildItem c:\state -Filter *.log | Sort LastWriteTime -Desc | Select -First 1).FullName -Tail 30"'

# Stale registration recovery (after VM reboot if scheduler still holds old session)
ssh ltsc2025-3 'sc stop ltsc2025-3'
ci3-admin forget windows-x86_64 ltsc2025-3
ssh ltsc2025-3 'sc start ltsc2025-3'
```

See `~/.claude/projects/-home-mtelvers-windows-worker/memory/ocluster-worker-troubleshooting.md` for failure-mode patterns.
