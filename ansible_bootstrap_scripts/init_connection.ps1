### RUN THIS SCRIPT WITH ADMINISTRATOR PRIVILEGES IF WINDOWS IS NOT INSTALLED VIA AUTOUNATTEND.XML TO INSTALL OPENSSH SERVER, TAILSCALE, AND CONFIGURE SSH ACCESS FOR ANSIBLE BOOTSTRAP ###

# Get the drive letter of the USB drive labeled 'ESD-USB'
$usb = (Get-Volume | Where-Object FileSystemLabel -eq 'ESD-USB').DriveLetter

# Copy the CompTechS folder from the USB drive to C:\Windows\CompTechS
Copy-Item -Path "${usb}:\CompTechS\" -Destination "C:\Windows\CompTechS" -Recurse -Force

# Install OpenSSH Server
Start-Process msiexec.exe -ArgumentList "/i C:\Windows\CompTechS\OpenSSH-Win64-v10.0.0.0.msi /qn" -Wait

# Install Tailscale
$msi = Get-ChildItem "C:\Windows\CompTechS\tailscale*.msi" | Select-Object -First 1
Start-Process msiexec.exe -ArgumentList "/i $($msi.FullName) /qn" -Wait

# Configure Windows Firewall to allow SSH traffic
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
}

# Copy the public key and sshd_config to the appropriate locations
New-Item -ItemType Directory -Path "C:\ProgramData\ssh" -Force
Copy-Item -Path "C:\Windows\CompTechS\openssh_key.pub" -Destination "C:\ProgramData\ssh\administrators_authorized_keys" -Force
Copy-Item -Path "C:\Windows\CompTechS\sshd_config" -Destination "C:\ProgramData\ssh\sshd_config" -Force 

# Set permissions for the .ssh directory and its contents
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /reset
icacls "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant:r "SYSTEM:F" /grant "Administrators:F"

# Start the sshd service and set it to start automatically on boot
Start-Service sshd;
Set-Service -Name sshd -StartupType 'Automatic';

# Wait for services to start properly before attempting to connect with Tailscale
Start-Sleep -Seconds 100

# Start Tailscale with the provided auth key to connect to the network
$authkey = (Get-Content "C:\Windows\CompTechS\tailscale_client.key" -Raw).Trim()
Start-Process -FilePath "C:\Program Files\Tailscale\tailscale.exe" `
    -ArgumentList @("up", "--authkey", $authkey) `
    -NoNewWindow -Wait -PassThru