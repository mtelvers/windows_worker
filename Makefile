
WINVER ?= 2025

provision:
	ansible-playbook playbook.yml -e winver=$(WINVER)

clean:
	rm -f unattend.iso autounattend.xml .windows-installed
