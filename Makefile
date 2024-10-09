
hosts:
	echo "[workers]" > hosts
	for h in 1 2 3 4 ; do virsh domid windows_worker_ltsc2022-$$h ; if [ $$? = 0 ] ; then echo ltsc2022-$$h ansible_host=`virsh net-dhcp-leases default $$(virsh dumpxml windows_worker_ltsc2022-$$h | xpath -e 'string(//mac/@address)' -q) | sed -ne 's/.*\s\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/p'` >> hosts ; fi ; done
	for h in 1 2 3 4 ; do virsh domid windows_worker_ltsc2019-$$h ; if [ $$? = 0 ] ; then echo ltsc2019-$$h ansible_host=`virsh net-dhcp-leases default $$(virsh dumpxml windows_worker_ltsc2019-$$h | xpath -e 'string(//mac/@address)' -q) | sed -ne 's/.*\s\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/p'` >> hosts ; fi ; done
	ansible -m win_ping -v all
	#ansible-playbook playbook.yml
