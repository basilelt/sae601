# This file handles GitLab VM provisioning after the VM is created

# Example of user_data for cloud-init (if needed)
resource "local_file" "cloud_init_user_data" {
  content  = templatefile("${path.module}/templates/user_data.yml.tpl", {
    hostname      = "gitlab.basile.local"
    ssh_public_key = var.ssh_public_key
    root_password = var.root_password
  })
  filename = "${path.module}/files/user_data.yml"
}

# Wait for VM to be ready for SSH connection
resource "null_resource" "wait_for_vm" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for VM to become available..."
      count=0
      max_attempts=30
      
      while ! ping -c 1 -W 1 ${var.ip_address} && [ $count -lt $max_attempts ]; do
        echo "VM not yet reachable (attempt $count/$max_attempts), waiting..."
        sleep 10
        count=$((count+1))
      done
      
      if [ $count -lt $max_attempts ]; then
        echo "VM is now reachable at ${var.ip_address}"
        # Give SSH some time to start up
        sleep 20
      else
        echo "Failed to reach VM after $max_attempts attempts"
        exit 1
      fi
    EOT
  }
}

# Provision the VM after it's ready
resource "null_resource" "gitlab_provisioning" {
  depends_on = [null_resource.wait_for_vm]
  
  provisioner "remote-exec" {
    inline = ["echo 'SSH connection established successfully'"]
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
      timeout  = "5m"
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/setup.sh"
    destination = "/tmp/setup.sh"
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
    }
  }
  
  provisioner "file" {
    source      = "${path.module}/scripts/install_gitlab.sh"
    destination = "/tmp/install_gitlab.sh"
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
    }
  }
  
  provisioner "file" {
    source      = "${path.module}/scripts/install_docker.sh"
    destination = "/tmp/install_docker.sh"
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "chmod +x /tmp/install_gitlab.sh",
      "chmod +x /tmp/install_docker.sh",
      "echo 'Running setup script first...'",
      "bash /tmp/setup.sh",
      "echo 'Installing Docker...'",
      "bash /tmp/install_docker.sh",
      "echo 'Now installing GitLab...'",
      "bash /tmp/install_gitlab.sh"
    ]
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
    }
  }
}
