# Host Name Resolution Configuration

This document explains how to configure your local machine's hosts file to resolve the hostnames used in this project.

## What is the hosts file?

The hosts file is a local file that maps hostnames to IP addresses. It's used by your operating system to resolve hostnames before querying DNS servers.

## Configuring the hosts file

### Location of the hosts file:

- **Linux/macOS**: `/etc/hosts`
- **Windows**: `C:\Windows\System32\drivers\etc\hosts`

### Edit the hosts file:

#### On Linux/macOS:
```bash
sudo nano /etc/hosts
```

#### On Windows:
1. Open Notepad as Administrator
2. File > Open > Navigate to `C:\Windows\System32\drivers\etc\`
3. Change the file filter from "Text Documents (*.txt)" to "All Files"
4. Select the `hosts` file and open it

## Add the following entries:

Add these lines to the end of your hosts file:

```
192.168.2.10       proxmox.basile.local
192.168.2.11       gitlab.basile.local
192.168.2.12       master1.basile.local
192.168.2.13       master2.basile.local
192.168.2.14       master3.basile.local
```

## Verify the configuration

After saving the hosts file, you can verify the configuration using ping:

```bash
ping gitlab.basile.local
```

You should see responses from the corresponding IP address.

## Notes

- Administrative privileges are required to modify the hosts file
- Some applications may cache DNS results, requiring a restart after modifying the hosts file
- If you're using a corporate network, VPN, or special DNS configuration, consult with your network administrator before making changes
