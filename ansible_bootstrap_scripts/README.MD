# Windows Unattended Installation with Wi-Fi and PowerShell Scripts

This guide shows how to create and use an unattended Windows installation (`autounattended.xml`) from [schneegans.de](https://schneegans.de/windows/unattend-generator), set up Wi-Fi using `netsh.exe`, and run two post-install PowerShell scripts (`unattend-01.ps1` and `unattend-02.ps1`).

---

## How to Generate `autounattended.xml`

### Step 1. Visit [Schneegans Windows Unattended Generator](https://schneegans.de/windows/unattend-generator).  
### Step 2. Fill out the configuration fields to your liking - important fields:
   - Bypass Windows 11 requirements check
   - User accounts: Setup one user account name Student as Administrators with no password
   - Prevent device encryption - **VERY IMPORTANT**
   - Visual effects: Adjust for best performance (optional)
### Step 3. Run ```netsh.exe wlan export profile key=clear``` to get the wifi profiles and put the content of the selected wifi in ```WLAN/WIFI setup``` 
### Step 4. In the ```Run custom scripts``` section, include:
   - in System scripts as a ps1 file: 
```
$usb = (Get-Volume | Where-Object FileSystemLabel -eq 'ESD-USB').DriveLetter
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${usb}:\CompTechS\unattend-01.ps1"
```
   - in FirstLogon scripts as a ps1 file:
   ```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Windows\CompTechS\broadcast_script.ps1"
   ```
### Step 5. Download the generated `autounattended.xml`.  