
# Ansible

Ensure you are running Vagrant 2.3.8 or later.

# Create a pool of Windows Workers

Create the Worker VMs by running:

```
vagrant up
```

> The `Vagrantfile` defines some VMs.  Edit the for loop in `Vagrantfile` to create more.

Create a `hosts` file for Ansible by running

```
make
```

The resulting file should look similar to the one shown below.  It is populated from the DHCP leases available via `virsh net-dhcp-leases default`

```
[workers]
ltsc2022-1 ansible_host=192.168.122.76
ltsc2022-2 ansible_host=192.168.122.181
ltsc2022-3 ansible_host=192.168.122.20
```

Run the playbook with

```
ansible-playbook playbook.yml
```

