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
  (1..4).each do |i|
    config.vm.define "ltsc2022-#{i}" do |ltsc2022|
      ltsc2022.vm.box = "windows-2022-standard-core"
      ltsc2022.vm.hostname = "ltsc2022-#{i}"
      ltsc2022.vm.provider :libvirt do |libvirt|
        libvirt.memory = "32768"
        libvirt.cpus = "8"
        libvirt.machine_virtual_size = 120
      end
    end
  end

  # Worker 2019
  (1..4).each do |i|
    config.vm.define "ltsc2019-#{i}" do |ltsc2022|
      ltsc2022.vm.box = "windows-2019-standard-core"
      ltsc2022.vm.hostname = "ltsc2019-#{i}"
      ltsc2022.vm.provider :libvirt do |libvirt|
        libvirt.memory = "32768"
        libvirt.cpus = "8"
        libvirt.machine_virtual_size = 120
      end
    end
  end

end
