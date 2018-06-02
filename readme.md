#This template is a monolithic template provisioning 3 web servers in a front end subnet, 2 db server in a backend subnet and a bastion servr with ansible in a bastion subnet
#Bastion subnet is the only available through RDP. Only http/s is available on front end subnet and no external access is allowed on backend subnet
#a custom script extension install iis on the front end
#The same as the basic linux, but with Windows VMs