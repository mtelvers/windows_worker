# -*- mode: ruby -*-
# vi: set ft=ruby :
#

# configure users session for libvirt
Vagrant.configure("2") do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.qemu_use_session = true
    libvirt.uri = 'qemu:///session'
    libvirt.nested = true
    libvirt.graphics_type = 'vnc'
    libvirt.cpu_model = "host-passthrough"
    # libvirt.management_network_device = 'virbr0'
  end

  # Worker
  (1..2).each do |i|
    config.vm.define "ltsc2025-#{i}" do |ltsc2025|
      ltsc2025.vm.box = "windows-2025-standard-core"
      ltsc2025.vm.hostname = "ltsc2025-#{i}"
      ltsc2025.vm.provider :libvirt do |libvirt|
        libvirt.memory = "32768"
        libvirt.cpus = "8"
        libvirt.machine_virtual_size = 240
      end
    end
  end

  # Worker 2019
  (1..2).each do |i|
    config.vm.define "ltsc2019-#{i}" do |ltsc2019|
      ltsc2019.vm.box = "windows-2019-standard-core"
      ltsc2019.vm.hostname = "ltsc2019-#{i}"
      ltsc2019.vm.provider :libvirt do |libvirt|
        libvirt.memory = "32768"
        libvirt.cpus = "8"
        libvirt.machine_virtual_size = 240
      end
    end
  end

end
