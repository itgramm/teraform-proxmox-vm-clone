# Proxmox VM + Terraform

While studying Terraform, I decided to try implementing automatic VM deployment on Proxmox VM.
To set up and test a home k3s cluster, it was decided to automate the installation of virtual machines. Previously, I had already performed automatic VM installation and [setup of a Kubernetes cluster using Ansible](https://github.com/itgramm/k8s-home).

## File Structure Description:

* [credentials_sample.tfvars](https://github.com/itgramm/teraform-proxmox-vm-clone/blob/main/credentials_sample.tfvars) — a variables file with specified values.
* [variables.tf](https://github.com/itgramm/teraform-proxmox-vm-clone/blob/main/variables.tf) — configuration file for variables.
* [provider.tf](https://github.com/itgramm/teraform-proxmox-vm-clone/blob/main/provider.tf)~~ — provider configuration file.
* [main.tf](https://github.com/itgramm/teraform-proxmox-vm-clone/blob/main/main.tf)~~ — resource configuration files.

## Terraform Installation

Linux
#### Ubuntu/Debian
```
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt-get install terraform

```

#### CentOS/RHEL
```
sudo yum install -y yum-utils

sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum -y install terraform
```

#### MacOS

```
brew tap hashicorp/tap

brew install hashicorp/tap/terraform

```

#### Windows
```
choco install terraform
```


## Preparing VM Image for Cloning

```
# installing libguestfs-tools only required once, prior to first run
sudo apt update -y
sudo apt install libguestfs-tools -y

# download a debian cloud-init disk image:
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

sudo virt-customize -a jammy-server-cloudimg-amd64.img --install qemu-guest-agent

sudo qm create 900 --name "ubuntu22.04" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

sudo qm importdisk 900 jammy-server-cloudimg-amd64.img local-lvm

sudo qm set 900 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-900-disk-0

sudo qm set 900 --boot c --bootdisk scsi0

sudo qm set 900 --ide2 local-lvm:cloudinit
sudo qm set 900 --serial0 socket --vga serial0
sudo qm set 900 --agent enabled=1
sudo qm template 900

rm jammy-server-cloudimg-amd64.img

```

## Obtaining API for Working with Proxmox VM

To enable Terraform to interact with Proxmox VM, we need to create a user and generate an API.
To create a user named tfuser and generate an API, we need to execute the following commands.

```
pveum role add TerraformProv -privs "Pool.Allocate VM.Console VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"

pveum user add tfuser@pve

pveum aclmod / -user tfuser@pve -role TerraformProv

pveum user token add tfuser@pve terraform --privsep 0
```

Be sure to save the API since it won't be stored anywhere else, and displaying it again will be impossible.

## Variable Descriptions
The file [credentials_sample.tfvars](https://github.com/itgramm/teraform-proxmox-vm-clone/blob/main/credentials_sample.tfvars) contains the following variables:

```
proxmox_api_url = "https://srv.proxmox.node/api2/json"  # Proxmox IP address or URL
proxmox_api_token_id = "terraform-prov@pve!terraform"  # API user ID
proxmox_api_token_secret = "dgfl8d47-615z-0712-bc7c-46e5a4ed8c5" # API Token ID
ssh_key = "ssh-ed25519 AAAAC3......" # ssh key that will be added to the user 
template_name = "ubuntu22.04" # the name of the virtual machine to clone 
target_node = "srv" # name of node 
cores = 2 
sockets = 1
memory = 4096
disk_size = "20G"
disk_storage = "local-lvm"
network_bridge = "vmbr0"
disk_type = "scsi"
network_model = "virtio"
network_ip = "192.168.1.24" 
network_gateway = "192.168.1.1"
user_name = "k3suser" # user name for new VM 
user_password = "password"  # password for new user
```

## Cloning VM

Copy the file credentials_sample.tfvars and rename it to credentials.tfvars.

Initialize Terraform. This will load necessary plugins and modules.

```
terraform init
```

Let's initiate the cloning process.

```
terraform apply -var-file=credentials.tfvars
```

To delete all VMs that have been created, let's run the command with the argument `-destroy`

```
terraform apply -destroy -var-file=credentials.tfvars
```
