###############################################
# USB-Based OpenSSH Server Setup Script
#
# Description:
# This script automates the installation and configuration of OpenSSH Server
# on a Windows machine using files stored on a USB drive labeled 'ESD-USB'.
#
# Steps performed:
# 1. Detects the drive letter of the USB drive labeled 'ESD-USB'.
# 2. Installs OpenSSH Server from the USB using the MSI installer.
# 3. Configures Windows Firewall to allow incoming SSH traffic on port 22.
# 4. Creates the SSH folder (C:\ProgramData\ssh) if it does not exist.
# 5. Copies the public key (ansible_ssh_key) and sshd_config 
#    to the system's SSH directory.
# 6. Sets directory and file permissions to allow SSH access for the
#    specified user ('Student').
# 7. Starts the sshd service and configures it to start automatically on boot.
#
# Purpose:
# Enables passwordless SSH access for management or automation tasks (e.g., Ansible)
# on Windows hosts using a pre-prepared USB drive.
###############################################

# Get the drive letter of the USB drive labeled 'ESD-USB'
$usb = (Get-Volume | Where-Object FileSystemLabel -eq 'ESD-USB').DriveLetter

# Copy the CompTechS folder from the USB drive to C:\Windows\CompTechS
Copy-Item -Path "${usb}:\CompTechS\" -Destination "C:\Windows\CompTechS" -Recurse -Force

# Install OpenSSH Server
msiexec /i "C:\Windows\CompTechS\OpenSSH-Win64-v10.0.0.0.msi"

# Configure Windows Firewall to allow SSH traffic
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

# Copy the public key and sshd_config to the appropriate locations
New-Item -ItemType Directory -Path "C:\ProgramData\ssh" -Force
Copy-Item -Path "C:\Windows\CompTechS\ansible_ssh_key.pub" -Destination "C:\ProgramData\ssh\administrators_authorized_keys" -Force
Copy-Item -Path "C:\Windows\CompTechS\sshd_config" -Destination "C:\ProgramData\ssh\sshd_config" -Force 

# Set permissions for the .ssh directory and its contents
icacls $sshFolder /inheritance:r /grant:r "Student:F" /T

# Start the sshd service and set it to start automatically on boot
Start-Service sshd;
Set-Service -Name sshd -StartupType 'Automatic';
