#cloud-config
hostname: ${hostname}
fqdn: ${hostname}
manage_etc_hosts: true

users:
  - name: root
    lock_passwd: false
    hashed_passwd: ${root_password}
    ssh_authorized_keys:
      - ${ssh_public_key}

# Update and upgrade packages
package_update: true
package_upgrade: true

# Install packages
packages:
  - openssh-server
  - curl
  - ca-certificates
  - apt-transport-https
  - gnupg
  - lsb-release

# Configure SSH
ssh_pwauth: true
