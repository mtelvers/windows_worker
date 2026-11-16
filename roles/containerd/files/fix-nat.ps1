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
# the HNS service, and on 2026-11-13 ltsc2025-3 won that race: the task
# exited 1 on "No NAT network found" and the machine then ran for three days
# with a subnet from the previous boot in its CNI config, failing every
# (network host) step.
Import-Module c:\windows\hns.psm1

$deadline = (Get-Date).AddMinutes(5)
while ($true) {
    $net = Get-HnsNetwork | Where-Object { $_.Name -eq 'nat' }
    if ($net -and $net.Subnets[0].AddressPrefix) { break }
    if ((Get-Date) -ge $deadline) {
        Write-Error "No NAT network found after 5 minutes"
        exit 1
    }
    Start-Sleep -Seconds 5
}

$subnet = $net.Subnets[0].AddressPrefix
$gateway = $net.Subnets[0].GatewayAddress
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
$json | Set-Content 'C:\Program Files\containerd\cni\conf\0-containerd-nat.conf' -Encoding ASCII
Write-Host "CNI config updated: subnet=$subnet gateway=$gateway"
