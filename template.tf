/*This template aims is to create the following architecture
1 RG
1 vNET
1 Subnet FrontEnd
1 Subnet BackEnd
1 Subnet Bastion
2 VM FrontEnd Web IIS + Azure LB
2 VM Backend DB MSSQL
1 VM RDP Bastion
1 public IP on FrontEnd
1 public IP on Bastion
1 external AzureLB
AzureManagedDIsk
NSG on FrontEnd Subnet
    Allow HTTP HTTPS from Internet through ALB
    Allow Access to internet egress
    Allow MSSQL to DB Tier
NSG on Backend Subnet
    Allow MSSQL Access from Web tier
    Allow egress Internet
NSG on Bastion
    Allow RDP from internet
    Allow RDP to all subnet
    Allow Internet access egress

*/
######################################################################
# Access to Azure
######################################################################

# Configure the Microsoft Azure Provider with Azure provider variable defined in AzureDFProvider.tf

provider "azurerm" {
  subscription_id = "${var.AzureSubscriptionID2}"
  client_id       = "${var.AzureClientID}"
  client_secret   = "${var.AzureClientSecret}"
  tenant_id       = "${var.AzureTenantID}"
}

######################################################################
# Foundations resources, including ResourceGroup and vNET
######################################################################

# Creating the ResourceGroup

resource "azurerm_resource_group" "RG-BasicWin" {
  name     = "${var.RGName}"
  location = "${var.AzureRegion}"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating vNET

resource "azurerm_virtual_network" "vNET-BasicWin" {
  name                = "vNET-BasicWin"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"
  address_space       = ["10.0.0.0/20"]
  location            = "${var.AzureRegion}"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

######################################################################
# Network security, NSG and subnet
######################################################################

# Creating NSG for FrontEnd

resource "azurerm_network_security_group" "NSG-Subnet-BasicWinFrontEnd" {
  name                = "NSG-Subnet-BasicWinFrontEnd"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"
}

#############################################
# Rules Section
#############################################

# Rule for incoming HTTP from internet

resource "azurerm_network_security_rule" "AlltoFrontEnd-OK-HTTPIN" {
  name                        = "OK-http-Inbound"
  priority                    = 1100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.0.0/24"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinFrontEnd.name}"
}

# Rule for incoming HTTPS from internet

resource "azurerm_network_security_rule" "AlltoFrontEnd-OK-HTTPSIN" {
  name                        = "AlltoFrontEnd-OK-HTTPSIN"
  priority                    = 1101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.0.0/24"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinFrontEnd.name}"
}

# Rule for incoming SSH from Bastion

resource "azurerm_network_security_rule" "BastiontoFrontEnd-OK-RDPIN" {
  name                        = "BastiontoFrontEnd-OK-RDPIN"
  priority                    = 1102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "10.0.0.0/24"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinFrontEnd.name}"
}

#Rule for outbound to Internet traffic

resource "azurerm_network_security_rule" "FrontEndtoInternet-OK-All" {
  name                        = "FrontEndtoInternet-OK-All"
  priority                    = 1103
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinFrontEnd.name}"
}

# Creating Subnet FrontEnd

resource "azurerm_subnet" "Subnet-BasicWinFrontEnd" {
  name                      = "Subnet-BasicWinFrontEnd"
  resource_group_name       = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_network_name      = "${azurerm_virtual_network.vNET-BasicWin.name}"
  address_prefix            = "10.0.0.0/24"
  network_security_group_id = "${azurerm_network_security_group.NSG-Subnet-BasicWinFrontEnd.id}"
}

# Creating NSG for Backend

resource "azurerm_network_security_group" "NSG-Subnet-BasicWinBackEnd" {
  name                = "NSG-Subnet-BasicWinBackEnd"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"
}

#############################################
# Rules Section
#############################################

# Rule for incoming MySQL from FE

resource "azurerm_network_security_rule" "AlltoFrontEnd-OK-MSSQLSQLIN" {
  name                        = "OK-http-Inbound"
  priority                    = 1100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.1.0/24"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinBackEnd.name}"
}

# Rule for incoming SSH from Bastion

resource "azurerm_network_security_rule" "BastiontoBackEnd-OK-RDPIN" {
  name                        = "BastiontoBackEnd-OK-RDPIN"
  priority                    = 1101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "10.0.1.0/24"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinBackEnd.name}"
}

#Rule for outbound to Internet traffic

resource "azurerm_network_security_rule" "BackEndtoInternet-OK-All" {
  name                        = "BackEndtoInternet-OK-All"
  priority                    = 1102
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.1.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinBackEnd.name}"
}

# Rule for incoming SSH from Internet

resource "azurerm_network_security_rule" "AlltoBackEnd-OK-RDPIN" {
  name                        = "AlltoBackEnd-OK-RDPIN"
  priority                    = 1103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.1.0/24"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinBackEnd.name}"
}

# Creating Subnet Backend

resource "azurerm_subnet" "Subnet-BasicWinBackEnd" {
  name                      = "Subnet-BasicWinBackEnd"
  resource_group_name       = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_network_name      = "${azurerm_virtual_network.vNET-BasicWin.name}"
  address_prefix            = "10.0.1.0/24"
  network_security_group_id = "${azurerm_network_security_group.NSG-Subnet-BasicWinBackEnd.id}"
}

# Creating NSG for Bastion

resource "azurerm_network_security_group" "NSG-Subnet-BasicWinBastion" {
  name                = "NSG-Subnet-BasicWinBastion"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"
}

#############################################
# Rules Section
#############################################

# Rule for incoming SSH from Internet

resource "azurerm_network_security_rule" "AlltoBastion-OK-RDPIN" {
  name                        = "AlltoBastion-OK-RDPIN"
  priority                    = 1101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "TCP"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.0.2.0/24"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinBastion.name}"
}

# Rule for outgoing internet traffic
resource "azurerm_network_security_rule" "BastiontoInternet-OK-All" {
  name                        = "BastiontoInternet-OK-All"
  priority                    = 1102
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.2.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.RG-BasicWin.name}"
  network_security_group_name = "${azurerm_network_security_group.NSG-Subnet-BasicWinBastion.name}"
}

# Creating Subnet Bastion

resource "azurerm_subnet" "Subnet-BasicWinBastion" {
  name                      = "Subnet-BasicWinBastion"
  resource_group_name       = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_network_name      = "${azurerm_virtual_network.vNET-BasicWin.name}"
  address_prefix            = "10.0.2.0/24"
  network_security_group_id = "${azurerm_network_security_group.NSG-Subnet-BasicWinBastion.id}"
}

######################################################################
# Public IP Address
######################################################################

# Creating Public IP for Load Balancer on FrontEnd

resource "random_string" "PublicIPfqdnprefixFE" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

resource "azurerm_public_ip" "PublicIP-FrontEndBasicWin" {
  name                         = "PublicIP-FrontEndBasicWin"
  location                     = "${var.AzureRegion}"
  resource_group_name          = "${azurerm_resource_group.RG-BasicWin.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${random_string.PublicIPfqdnprefixFE.result}dvtweb"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating Public IP for Bastion

resource "random_string" "PublicIPfqdnprefixBastion" {
  length  = 5
  special = false
  upper   = false
  number  = false
}

resource "azurerm_public_ip" "PublicIP-BastionBasicWin" {
  name                         = "PublicIP-BastionBasicWin"
  location                     = "${var.AzureRegion}"
  resource_group_name          = "${azurerm_resource_group.RG-BasicWin.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${random_string.PublicIPfqdnprefixBastion.result}dvtbastion"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

######################################################################
# Load Balancing
######################################################################

# Creating Azure Load Balancer for front end http / https

resource "azurerm_lb" "LB-WebFrontEndBasicWin" {
  name                = "LB-WebFrontEndBasicWin"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"

  frontend_ip_configuration {
    name                 = "weblbBasicWin"
    public_ip_address_id = "${azurerm_public_ip.PublicIP-FrontEndBasicWin.id}"
  }

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating Back-End Address Pool

resource "azurerm_lb_backend_address_pool" "LB-WebFRontEndBackEndPool" {
  name                = "LB-WebFRontEndBackEndPool"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"
  loadbalancer_id     = "${azurerm_lb.LB-WebFrontEndBasicWin.id}"
}

# Creating Health Probe

resource "azurerm_lb_probe" "LB-WebFrontEnd-httpprobe" {
  name                = "LB-WebFrontEnd-httpprobe"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"
  loadbalancer_id     = "${azurerm_lb.LB-WebFrontEndBasicWin.id}"
  port                = 80
}

# Creating Load Balancer rules

resource "azurerm_lb_rule" "LB-WebFrondEndrule" {
  name                           = "LB-WebFrondEndrule"
  resource_group_name            = "${azurerm_resource_group.RG-BasicWin.name}"
  loadbalancer_id                = "${azurerm_lb.LB-WebFrontEndBasicWin.id}"
  protocol                       = "tcp"
  probe_id                       = "${azurerm_lb_probe.LB-WebFrontEnd-httpprobe.id}"
  frontend_port                  = 80
  frontend_ip_configuration_name = "weblbBasicWin"
  backend_port                   = 80
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.LB-WebFRontEndBackEndPool.id}"
}

###########################################################################
# Managed Disk creation
###########################################################################

# Managed disks for Web frontend VMs

resource "azurerm_managed_disk" "WebFrontEndManagedDisk" {
  count                = 3
  name                 = "WebFrontEnd-${count.index + 1}-Datadisk"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "127"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Managed disks for Web DB Backend VMs

resource "azurerm_managed_disk" "DBBackEndManagedDisk" {
  count                = 2
  name                 = "DBBackEnd-${count.index + 1}-Datadisk"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "127"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Managed disks for Bastion VM

resource "azurerm_managed_disk" "BastionManagedDisk" {
  count                = 1
  name                 = "Bastion-${count.index + 1}-Datadisk"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = "127"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

###########################################################################
#NICs creation
###########################################################################

# NIC Creation for Web FrontEnd VMs

resource "azurerm_network_interface" "WebFrontEndNIC" {
  count               = 3
  name                = "WebFrontEnd${count.index +1}-NIC"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"

  ip_configuration {
    name                                    = "ConfigIP-NIC${count.index + 1}-WebFrontEnd${count.index + 1}"
    subnet_id                               = "${azurerm_subnet.Subnet-BasicWinFrontEnd.id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.LB-WebFRontEndBackEndPool.id}"]
  }

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# NIC Creation for DB BackEnd VMs

resource "azurerm_network_interface" "DBBackEndNIC" {
  count               = 2
  name                = "DBBackEnd${count.index +1}-NIC"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"

  ip_configuration {
    name                          = "ConfigIP-NIC${count.index + 1}-DBBackEnd${count.index + 1}"
    subnet_id                     = "${azurerm_subnet.Subnet-BasicWinBackEnd.id}"
    private_ip_address_allocation = "dynamic"
  }

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# NIC Creation for Bastion VMs

resource "azurerm_network_interface" "BastionNIC" {
  count               = 1
  name                = "Bastion${count.index +1}-NIC"
  location            = "${var.AzureRegion}"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"

  ip_configuration {
    name                          = "ConfigIP-NIC${count.index + 1}-Bastion${count.index + 1}"
    subnet_id                     = "${azurerm_subnet.Subnet-BasicWinBastion.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.PublicIP-BastionBasicWin.id}"
  }

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

###########################################################################
#VMs Creation
###########################################################################

# Availability Set for Web FrontEnd VMs

resource "azurerm_availability_set" "BasicWinWebFrontEnd-AS" {
  name                = "BasicWinWebFrontEnd-AS"
  location            = "${var.AzureRegion}"
  managed             = "true"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Availability Set for BackEnd VMs

resource "azurerm_availability_set" "BasicWinDBBackEnd-AS" {
  name                = "BasicWinDBBackEnd-AS"
  location            = "${var.AzureRegion}"
  managed             = "true"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Availability Set for Bastion VM

resource "azurerm_availability_set" "BasicWinBastion-AS" {
  name                = "BasicWinBastion-AS"
  location            = "${var.AzureRegion}"
  managed             = "true"
  resource_group_name = "${azurerm_resource_group.RG-BasicWin.name}"

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Web FrontEnd VMs creation

resource "azurerm_virtual_machine" "BasicWinWebFrontEndVM" {
  count                 = 3
  name                  = "BasicWinWebFrontEnd${count.index +1}"
  location              = "${var.AzureRegion}"
  resource_group_name   = "${azurerm_resource_group.RG-BasicWin.name}"
  network_interface_ids = ["${element(azurerm_network_interface.WebFrontEndNIC.*.id, count.index)}"]
  vm_size               = "${lookup(var.VMSize,1)}"
  availability_set_id   = "${azurerm_availability_set.BasicWinWebFrontEnd-AS.id}"
  depends_on            = ["azurerm_network_interface.WebFrontEndNIC"]

  storage_image_reference {
    publisher = "${lookup(var.OSPublisher,0)}"
    offer     = "${lookup(var.OSOffer,0)}"
    sku       = "${lookup(var.OSsku,0)}"
    version   = "${var.OSversion}"
  }

  storage_os_disk {
    name              = "WebFrontEnd-${count.index + 1}-OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.WebFrontEndManagedDisk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.WebFrontEndManagedDisk.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${element(azurerm_managed_disk.WebFrontEndManagedDisk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "WebFrontEnd${count.index + 1}"
    admin_username = "${var.VMAdminName}"
    admin_password = "${var.VMAdminPassword}"
  }

  os_profile_windows_config {
    provision_vm_agent        = "true"
    enable_automatic_upgrades = "false"
  }

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# DB BackEnd VMs Creation

resource "azurerm_virtual_machine" "BasicWinDBBackEndVM" {
  count                 = 2
  name                  = "BasicWinDBBackEnd${count.index +1}"
  location              = "${var.AzureRegion}"
  resource_group_name   = "${azurerm_resource_group.RG-BasicWin.name}"
  network_interface_ids = ["${element(azurerm_network_interface.DBBackEndNIC.*.id, count.index)}"]
  vm_size               = "${lookup(var.VMSize,2)}"
  availability_set_id   = "${azurerm_availability_set.BasicWinDBBackEnd-AS.id}"
  depends_on            = ["azurerm_network_interface.DBBackEndNIC"]

  storage_image_reference {
    publisher = "${lookup(var.OSPublisher,1)}"
    offer     = "${lookup(var.OSOffer,1)}"
    sku       = "${lookup(var.OSsku,1)}"
    version   = "${var.OSversion}"
  }

  storage_os_disk {
    name              = "DBBackEnd-${count.index + 1}-OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.DBBackEndManagedDisk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.DBBackEndManagedDisk.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${element(azurerm_managed_disk.DBBackEndManagedDisk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "DBBackEnd${count.index + 1}"
    admin_username = "${var.VMAdminName}"
    admin_password = "${var.VMAdminPassword}"
  }

  os_profile_windows_config {
    provision_vm_agent        = "true"
    enable_automatic_upgrades = "false"
  }

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Bastion VM Creation

resource "azurerm_virtual_machine" "BasicWinBastionVM" {
  count                 = 1
  name                  = "BasicWinBastion${count.index +1}"
  location              = "${var.AzureRegion}"
  resource_group_name   = "${azurerm_resource_group.RG-BasicWin.name}"
  network_interface_ids = ["${element(azurerm_network_interface.BastionNIC.*.id, count.index)}"]
  vm_size               = "${lookup(var.VMSize, 0)}"
  availability_set_id   = "${azurerm_availability_set.BasicWinBastion-AS.id}"
  depends_on            = ["azurerm_network_interface.BastionNIC"]

  storage_image_reference {
    publisher = "${lookup(var.OSPublisher,0)}"
    offer     = "${lookup(var.OSOffer,0)}"
    sku       = "${lookup(var.OSsku,0)}"
    version   = "${var.OSversion}"
  }

  storage_os_disk {
    name              = "Bastion-${count.index + 1}-OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name            = "${element(azurerm_managed_disk.BastionManagedDisk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.BastionManagedDisk.*.id, count.index)}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${element(azurerm_managed_disk.BastionManagedDisk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name  = "Bastion${count.index + 1}"
    admin_username = "${var.VMAdminName}"
    admin_password = "${var.VMAdminPassword}"
  }

  os_profile_windows_config {
    provision_vm_agent        = "true"
    enable_automatic_upgrades = "false"
  }

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine extension for Bastion

resource "azurerm_virtual_machine_extension" "CustomExtension-BasicWinBastion" {
  count                = 1
  name                 = "CustomExtensionBastion${count.index +1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "BasicWinBastion${count.index +1}"
  publisher            = "microsoft.compute"
  type                 = "customscriptextension"
  type_handler_version = "1.9"
  depends_on           = ["azurerm_virtual_machine.BasicWinBastionVM"]

  settings = <<SETTINGS
        {
        "commandToExecute": "powershell.exe -command install-windowsfeature telnet-client"
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine extension for FrontEnd

resource "azurerm_virtual_machine_extension" "CustomExtension-BasicWinFrontEnd" {
  count                = 3
  name                 = "CustomExtensionFrontEnd${count.index +1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "BasicWinWebFrontEnd${count.index +1}"
  publisher            = "microsoft.compute"
  type                 = "customscriptextension"
  type_handler_version = "1.9"
  depends_on           = ["azurerm_virtual_machine.BasicWinWebFrontEndVM"]

  settings = <<SETTINGS
        {   
        "commandToExecute": "powershell.exe -command install-windowsfeature web-server"
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine extension for Backend

resource "azurerm_virtual_machine_extension" "CustomExtension-BasicWinBackEnd" {
  count                = 2
  name                 = "CustomExtensionBackEnd${count.index +1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "BasicWinDBBackEnd${count.index +1}"
  publisher            = "microsoft.compute"
  type                 = "customscriptextension"
  type_handler_version = "1.9"
  depends_on           = ["azurerm_virtual_machine.BasicWinDBBackEndVM"]

  settings = <<SETTINGS
        {   
        "commandToExecute": "powershell.exe -command install-windowsfeature telnet-client"
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine Network watcher extension for Bastion

resource "azurerm_virtual_machine_extension" "Bastion-NetworkWatcherAgent" {
  count                = 1
  name                 = "NetworkWatcherAgent-Bastion${count.index+1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicWinBastionVM.*.name,count.index)}"
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentWindows"
  type_handler_version = "1.4"

  settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine Network watcher extension for FrontEnd

resource "azurerm_virtual_machine_extension" "FE-NetworkWatcherAgent" {
  count                = 3
  name                 = "NetworkWatcherAgent-Frontend${count.index+1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicWinWebFrontEndVM.*.name,count.index)}"
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentWindows"
  type_handler_version = "1.4"

  settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating virtual machine Network watcher extension for Backend

resource "azurerm_virtual_machine_extension" "BE-NetworkWatcherAgent" {
  count                = 2
  name                 = "NetworkWatcherAgent-Backend${count.index+1}"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicWinDBBackEndVM.*.name,count.index)}"
  publisher            = "Microsoft.Azure.NetworkWatcher"
  type                 = "NetworkWatcherAgentWindows"
  type_handler_version = "1.4"

  settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

# Creating BGInfo extension for Backend

resource "azurerm_virtual_machine_extension" "Bastion-BGInfoAgent" {
  count                = 1
  name                 = "Bastion${count.index+1}BGInfo"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicWinBastionVM.*.name,count.index)}"
  publisher            = "microsoft.compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"

  settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

resource "azurerm_virtual_machine_extension" "FE-BGInfoAgent" {
  count                = 3
  name                 = "FE${count.index+1}BGInfo"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicWinWebFrontEndVM.*.name,count.index)}"
  publisher            = "microsoft.compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"

  settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

resource "azurerm_virtual_machine_extension" "BE-BGInfoAgent" {
  count                = 2
  name                 = "BE${count.index+1}BGInfo"
  location             = "${var.AzureRegion}"
  resource_group_name  = "${azurerm_resource_group.RG-BasicWin.name}"
  virtual_machine_name = "${element(azurerm_virtual_machine.BasicWinDBBackEndVM.*.name,count.index)}"
  publisher            = "microsoft.compute"
  type                 = "BGInfo"
  type_handler_version = "2.1"

  settings = <<SETTINGS
        {   
        
        "commandToExecute": ""
        }
SETTINGS

  tags {
    environment = "${var.TagEnvironment}"
    usage       = "${var.TagUsage}"
  }
}

#####################################################################################
# Output
#####################################################################################

output "Bastion Public IP" {
  value = ["${azurerm_public_ip.PublicIP-BastionBasicWin.*.ip_address}"]
}

output "Bastion FQDN" {
  value = ["${azurerm_public_ip.PublicIP-BastionBasicWin.*.fqdn}"]
}

output "Azure LB Public IP" {
  value = "${azurerm_public_ip.PublicIP-FrontEndBasicWin.ip_address}"
}

output "Azure Web LB FQDN " {
  value = "${azurerm_public_ip.PublicIP-FrontEndBasicWin.fqdn}"
}

output "DB VM Private IP" {
  value = ["${azurerm_network_interface.DBBackEndNIC.*.private_ip_address}"]
}

output "FE VM Private IP" {
  value = ["${azurerm_network_interface.WebFrontEndNIC.*.private_ip_address}"]
}

output "Web Load Balancer FE IP Config Name" {
  value = "${azurerm_lb.LB-WebFrontEndBasicWin.frontend_ip_configuration}"
}

