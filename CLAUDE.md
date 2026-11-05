# windows_worker

Ansible playbooks and configs for the OCluster Windows worker pool (`windows-x86_64`).

## Host layout

| Worker | SSH alias | Host | Notes |
|--------|-----------|------|-------|
| `ltsc2025-1` | `ssh ltsc2025-1` | `thyme.caelum.ci.dev:60022` | QEMU VM on thyme |
| `ltsc2025-2` | `ssh ltsc2025-2` | `thyme.caelum.ci.dev:60023` | QEMU VM on thyme |
| `ltsc2025-3` | `ssh ltsc2025-3` | `127.0.0.1:60022` | QEMU VM on this machine |

SSH aliases live in `~/.ssh/config`. All workers run Windows Server 2025.

## Per-worker layout (inside the Windows VM)

- Worker source: `C:\ocluster` (native opam/dune build, no Cygwin — see `roles/worker/tasks/main.yml`)
- State dir: `C:\state` — `worker-<pid>.log` per worker run; current run = newest file
- OBuilder store: `C:\obuilder` (HCS backend via containerd)
- Service name: lowercase `inventory_hostname_short` (e.g. `ltsc2025-3`)
- Capability file: `C:\windows\pool-windows-x86_64.cap`
- Manual start script: `C:\windows\go.bat`

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
