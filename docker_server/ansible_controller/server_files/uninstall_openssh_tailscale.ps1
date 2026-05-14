# -------------------------
# Tailscale removal
# -------------------------
Write-Host "Removing Tailscale..."

Stop-Service -Name "Tailscale" -Force -ErrorAction SilentlyContinue

# Uninstall Tailscale (MSI or Store version)
Get-WmiObject Win32_Product |
Where-Object { $_.Name -like "*Tailscale*" } |
ForEach-Object { $_.Uninstall() }

# Remove leftovers
Remove-Item -Recurse -Force "C:\Program Files\Tailscale" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\ProgramData\Tailscale" -ErrorAction SilentlyContinue

$log = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Removed Tailscale"
Add-Content -Path "C:\Windows\CompTechS\log.txt" -Value $log

# -------------------------
# OpenSSH Server removal
# -------------------------
Write-Host "Removing OpenSSH Server..."

# Stop and remove service
Stop-Service sshd -Force -ErrorAction SilentlyContinue

Get-WmiObject Win32_Product |
Where-Object { $_.Name -like "*OpenSSH*" } |
ForEach-Object { $_.Uninstall() }

# Remove leftover config
Remove-Item -Recurse -Force "C:\ProgramData\ssh" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\Program Files\OpenSSH" -ErrorAction SilentlyContinue

$log = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Removed OpenSSH"
Add-Content -Path "C:\Windows\CompTechS\log.txt" -Value $log

Copy-Item -Path "C:\Windows\CompTechS\log.txt" `
          -Destination "C:\Users\Student\Desktop\" `
          -Force

if (Test-Path "C:\Windows\CompTechS") {
    Remove-Item -Path "C:\Windows\CompTechS" -Recurse -Force
}

$log = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Removed CompTechS folder and copied log to Desktop"
Add-Content -Path "C:\Users\Student\Desktop\log.txt" -Value $log

$log = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Operation Completed. Please check if Tailscale and OpenSSH were uninstalled successfully. If you do not see logs of their removal in this file, please check if they are still installed and uninstall them manually if needed."
Add-Content -Path "C:\Users\Student\Desktop\SetupComplete.txt" -Value $log
