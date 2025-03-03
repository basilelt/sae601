#cloud-config

hostname: ${hostname}
fqdn: ${hostname}

users:
  - name: root
    lock_passwd: false
    hashed_passwd: ${root_password}

ssh_authorized_keys:
  - ${ssh_public_key}

runcmd:
  - apt-get update
  - apt-get upgrade -y
