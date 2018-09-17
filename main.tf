provider "azurerm" {
	subscription_id = "483e3fb6-7be5-4715-b41c-f1f8f7d2dd2a"
	client_id       = "e3ba3d8e-c9d2-48ce-bdb2-e655da0873c4"
	client_secret   = "264d6bd5-b0d5-483f-ac27-181d124428a4"
	tenant_id       = "e5af66ec-c0ee-41b6-bc79-e7470d8a1d16"
}
resource "azurerm_resource_group" "myterraformgroup" {
	name     = "myResourceGroup"
	location = "eastus"
	tags {
		environment = "Terraform Demo"
	}
}
resource "azurerm_virtual_network" "myterraformnetwork" {
	name                = "myVnet"
	address_space       = ["10.0.0.0/16"]
	location            = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

	tags {
		environment = "Terraform Demo"
	}
}
resource "azurerm_public_ip" "myterraformpublicip" {
	name                         = "myPublicIP"
	location                     = "eastus"
	resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
	public_ip_address_allocation = "dynamic"

	tags {
		environment = "Terraform Demo"
	}
}
resource "azurerm_subnet" "myterraformsubnet" {
	name = "mySubnet"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
	address_prefix = "10.0.2.0/24"
}
resource "azurerm_network_security_group" "myterraformnsg" {
	name                = "myNetworkSecurityGroup"
	location            = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

	security_rule {
		name                       = "SSH"
		priority                   = 1001
		direction                  = "Inbound"
		access                     = "Allow"
		protocol                   = "Tcp"
		source_port_range          = "*"
		destination_port_range     = "22"
		source_address_prefix      = "*"
		destination_address_prefix = "*"
	}

	tags {
		environment = "Terraform Demo"
	}
}
resource "azurerm_network_interface" "myterraformnic" {

	name = "myNIC"
	location = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

	ip_configuration {
		name = "myNicConfiguration"
		subnet_id = "${azurerm_subnet.myterraformsubnet.id}"
		private_ip_address_allocation = "dynamic"
		public_ip_address_id = "${azurerm_public_ip.myterraformpublicip.id}"
	}

	tags {
		environment = "Terraform Demo"
	}
}
resource "random_id" "randomId" {
	keepers = {
		# Generate a new ID only when a new resource group is defined
		resource_group = "${azurerm_resource_group.myterraformgroup.name}"
	}
	
	byte_length = 8
}
resource "azurerm_storage_account" "mystorageaccount" {
	name = "diag${random_id.randomId.hex}"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	location = "eastus"
	account_replication_type = "LRS"
	account_tier = "Standard"

	tags {
		environment = "Terraform Demo"
	}
}
resource "azurerm_virtual_machine" "myterraformvm" {
	name = "myVM"
	location = "eastus"
	resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
	network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
	vm_size = "Standard_DS1_v2"

	storage_os_disk {
		name = "myOsDisk"
		caching = "ReadWrite"
		create_option = "FromImage"
		managed_disk_type = "Premium_LRS"
	}

	storage_image_reference {
		publisher = "Canonical"
		offer = "UbuntuServer"
		sku = "16.04.0-LTS"
		version ="latest"
	}
	
	os_profile {
		computer_name = "myVM"
		admin_username = "stage"
	}
	
	os_profile_linux_config {
		disable_password_authentication = true
		ssh_keys {
			path ="/home/stage/.ssh/authorized_keys"
			key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHfYmi4iacSVl5PDtAkNYHLmOq5BKy76Og16siX6JztyjUYlCsKg+i+3sY/BTeishgQ9pLyo9zIWutVTafUqfL/IELt8/sSTpviAnfxXo6D2/xFOy1SwKsSuuTabl9LDVAE4mLX9DzPECeTJXf1XZ+8YtHvcZ8jjPt/bVFxB3v08rOVe/uRDtb+yVawI2OO1XoMEPIZ2699ZpVi8N4ujo1FVR8M1+T2DKAcup4Q1Oka7a5nvS3UVQfVIQYPJ1u3HXTSVhiDy1SMv/HHhhxWzKyZfQfefnNrNZs/ZsFUWRGemgEhjLfzhTrtrceyIZY4WE+Y+Oz+SSBnZIE70TA/s5da5hM6cCU12pWpMAsvXz21ClonMcZXWhCswanuat/5xl3g4q6BrFE+QBLmnman7YUe1MzoCgH/g5zEDxDTg7rPFfR9UYywCnT4cC9dHYFahZma3+ZI9L6+7tPHbsVvy8QLKtmnVjRnxRwDSCLV2AmLHQne0Cgzep5Hxq+vDh/aNnVKukp0rcxCyC6GqRUxzq14tEOMLTOXSL+JftxHafuPNnPcTU1C/m8maxtrXCYw10FAu2ZwSTRjOH2bvQf6Fo9B1NSkK0HeM0V8nyRVcPvqNcHuAZqt8n32NEhlZP4EZkGIEKwJWAbzspftS3sGogaMyAXf7TWVY+kJkKH/BeXWw== samodev1725@gmail.com"
		}
	}

	boot_diagnostics {
		enabled = "true"
		storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
	}

	tags {
		environment = "Terraform Demo"
	}
}
