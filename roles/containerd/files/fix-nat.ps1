# Read Docker's existing NAT network configuration and write it into the
# containerd CNI config so both runtimes share the same subnet.
Import-Module c:\windows\hns.psm1
$net = Get-HnsNetwork | Where-Object { $_.Name -eq 'nat' }
if (-not $net) {
    Write-Error "No NAT network found"
    exit 1
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
