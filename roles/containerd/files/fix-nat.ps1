# Read Docker's existing NAT network configuration and write it into the
# containerd CNI config so both runtimes share the same subnet.
#
# Windows reassigns the nat subnet on every boot, so this has to run after
# each one or containerd hands containers an address on a subnet that no
# longer exists: no route, no DNS. Docker is unaffected because it reads HNS
# directly, which is why a Docker container can resolve github.com on a host
# where an obuilder step fails with "Could not resolve host".
#
# Wait for the network rather than assuming it is up. The boot trigger races
# both HNS and dockerd, and dockerd can take minutes to create nat on a host
# with a large image store (1,981 images on ltsc2025-3). On 2026-11-13
# ltsc2025-3 won that race, exited 1 on "No NAT network found", and ran for
# three days with a subnet from the previous boot.
#
# Write via a temp file and only move it into place once the JSON is known
# good. On 2026-11-17 the scheduled run truncated the live config to 0 bytes:
# the values came back null while HNS was still settling, ConvertTo-Json
# returned null, and `$json | Set-Content` on the live path emptied it. An
# empty CNI config is worse than a stale one.
Import-Module c:\windows\hns.psm1

$target = 'C:\Program Files\containerd\cni\conf\0-containerd-nat.conf'
$deadline = (Get-Date).AddMinutes(10)

while ($true) {
    $net = @(Get-HnsNetwork | Where-Object { $_.Name -eq 'nat' })
    if ($net.Count -eq 1) {
        $subnet  = $net[0].Subnets[0].AddressPrefix
        $gateway = $net[0].Subnets[0].GatewayAddress
        if ($subnet -and $gateway) { break }
    }
    if ((Get-Date) -ge $deadline) {
        Write-Error "No usable NAT network after 10 minutes (found $($net.Count)); leaving $target untouched"
        exit 1
    }
    Start-Sleep -Seconds 5
}

$json = @{
    cniVersion = "0.3.0"
    name = "nat"
    type = "nat"
    master = "Ethernet"
    ipam = @{
        subnet = $subnet
        routes = @(@{ gateway = $gateway })
    }
    capabilities = @{
        portMappings = $true
        dns = $true
    }
} | ConvertTo-Json -Depth 3

# Never write the live file directly: validate, stage, then move.
if (-not $json -or $json.Length -lt 50) {
    Write-Error "Refusing to write a $($json.Length)-byte CNI config; leaving $target untouched"
    exit 1
}
try { $null = $json | ConvertFrom-Json } catch {
    Write-Error "Generated CNI config is not valid JSON; leaving $target untouched"
    exit 1
}

$tmp = "$target.tmp"
$json | Set-Content $tmp -Encoding ASCII
if ((Get-Item $tmp).Length -lt 50) {
    Write-Error "Staged CNI config is empty; leaving $target untouched"
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    exit 1
}
Move-Item $tmp $target -Force
Write-Host "CNI config updated: subnet=$subnet gateway=$gateway"
