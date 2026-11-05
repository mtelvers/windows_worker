
WINVER ?= 2025

# VMNAME overrides roles/qemu/defaults/main.yml's vm_name, e.g.
#   make provision VMNAME=ltsc2025-3
# Left empty the role default applies.
VMNAME ?=

provision:
	ansible-playbook playbook.yml -e winver=$(WINVER) $(if $(VMNAME),-e vm_name=$(VMNAME),)

clean:
	rm -f unattend.iso autounattend.xml .windows-installed
