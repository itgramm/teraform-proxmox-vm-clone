# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "k3s-master" {
    target_node = var.target_node
    count = 3
    name = "k3s-0${count.index + 1}"
    clone = var.template_name
    os_type = "cloud-init"
    cpu = "kvm64"
    cores = var.cores
    sockets = var.sockets
    memory = var.memory
    scsihw = "virtio-scsi-pci"
    bootdisk = "scsi0"
    vmid = "40${count.index + 1}"
    disk {
    slot     = 0
    size     = var.disk_size
    type     = var.disk_type
    storage  = var.disk_storage
    }
    network {
    model = var.network_model
    bridge = var.network_bridge
    firewall = false
    link_down = false
    }
    ipconfig0 = "ip=${var.network_ip}${count.index + 1}/22,gw=${var.network_gateway}"
    ciuser = var.user_name
    cipassword = var.user_password
    sshkeys   = <<EOF
    ${var.ssh_key}
    EOF

}