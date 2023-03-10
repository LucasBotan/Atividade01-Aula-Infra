
/*
Atividade 01
Subir uma máquina virtual no Azure, AWS ou GCP instalando o Apache2/nginx e que esteja acessível no host da máquina na porta 80, usando Terraform.
Enviar a URL GitHub do código.
O código enviado deve satisfazer exatamente o que foi pedido no enunciado, caso haja código faltando ou sobrando terá desconto de nota. 
Atividade pode ser feita em grupo ou individual.

Turma: FS05

Integrantes:
Silvia Cristina de Oliveira Teixeira
Guilherme Henrique Taira
Aldenir Rodrigues Almeida
Jessica Roza da Silva
Lucas Marques Botan
*/


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg-exercicio-infra" {
  name     = "rg-exercicio-infra"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet-exercicio-infra" {
  name                = "vnet-exercicio-infra"
  location            = azurerm_resource_group.rg-exercicio-infra.location
  resource_group_name = azurerm_resource_group.rg-exercicio-infra.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    faculdade = "IMPACTA"
    turma     = "FS-05"
    aula      = "INFRA"
  }
}

resource "azurerm_subnet" "sub-exercicio-infra" {
  name                 = "sub-exercicio-infra"
  resource_group_name  = azurerm_resource_group.rg-exercicio-infra.name
  virtual_network_name = azurerm_virtual_network.vnet-exercicio-infra.name
  address_prefixes     = ["10.0.1.0/24"]
}

#IMPORTANTE: LIBERAR A PORTA 80 (SE NÃO DER COM "HTTP" MUDAR PARA "Web")
resource "azurerm_network_security_group" "nsg-exercicio-infra" {
  name                = "nsg-exercicio-infra"
  location            = azurerm_resource_group.rg-exercicio-infra.location
  resource_group_name = azurerm_resource_group.rg-exercicio-infra.name

  security_rule {
    name                       = "HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    faculdade = "IMPACTA"
    turma     = "FS-05"
    aula      = "INFRA"
  }
}

#NÃO NECESSÁRIO
resource "azurerm_public_ip" "ip-exercicio-infra" {
  name                = "ip-exercicio-infra"
  resource_group_name = azurerm_resource_group.rg-exercicio-infra.name
  location            = azurerm_resource_group.rg-exercicio-infra.location
  allocation_method   = "Static"

  tags = {
    faculdade = "IMPACTA"
    turma     = "FS-05"
    aula      = "INFRA"
  }
}


resource "azurerm_network_interface" "nic-exercicio-infra" {
  name                = "nic-exercicio-infra"
  location            = azurerm_resource_group.rg-exercicio-infra.location
  resource_group_name = azurerm_resource_group.rg-exercicio-infra.name

  ip_configuration {
    name                          = "nic-internal"
    subnet_id                     = azurerm_subnet.sub-exercicio-infra.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ip-exercicio-infra.id
  }
}

resource "azurerm_virtual_machine" "vm-exercicio-infra" {
  name                  = "vm-exercicio-infra"
  location              = azurerm_resource_group.rg-exercicio-infra.location
  resource_group_name   = azurerm_resource_group.rg-exercicio-infra.name
  network_interface_ids = [azurerm_network_interface.nic-exercicio-infra.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "admim123"
    admin_password = "password@123"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    faculdade = "IMPACTA"
    turma     = "FS-05"
    aula      = "INFRA"
  }
}

#VERIFICAR SE PODE INSTALAR SÓ O APACHE OU É PRECISO O APACHE + NGINX
resource "null_resource" "install-apache" {

  triggers = {
    order=azurerm_virtual_machine.vm-exercicio-infra.id
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = azurerm_public_ip.ip-exercicio-infra.ip_address
      user     = "admim123"
      password = "password@123"
    }
    inline = [
      "sudo apt update",
      "sudo apt install -y apache2"
    ]
  }
}


/*
resource "null_resource" "install-nginx" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = azurerm_public_ip.ip-exercicio-infra.ip_adress
      user     = "admin"
      password = "admin"
    }
    inline = [
      "sudo apt update",
      "sudo apt install -y nginx"
    ]
  }
  #verificar a necessidade dessa parte no código
  depends_on = [
    azurerm_virtual_machine.vm-exercicio-infra.id
  ]
}
*/


