# Get the Tailscale MSI filename from the CompTechS directory
$msi = Get-ChildItem "C:\Windows\CompTechS\tailscale*.msi" | Select-Object -First 1

# Install Tailscale with specific parameters to prevent it from launching immediately and to set it to unattended mode
$MsiParameters = @{
    FilePath     = "msiexec.exe"
    Wait         = $true
    ArgumentList = @(
        "/i", "`"$($msi.FullName)`"",
        "/qn",
        "TS_NOLAUNCH=1",
        "TS_UNATTENDEDMODE=always"
    )
}
Start-Process @MsiParameters

Start-Sleep -Seconds 150

# Run scripts in order
# & "C:\Windows\CompTechS\set_default_browser_script.ps1"

# Start-Sleep -Seconds 60

# & "C:\Windows\CompTechS\set_edge_startup_page_icon_script.ps1"

# Start-Sleep -Seconds 30

$authkey = (Get-Content "C:\Windows\CompTechS\tailscale_client.key" -Raw).Trim()
Start-Process -FilePath "C:\Program Files\Tailscale\tailscale.exe" `
    -ArgumentList @("up", "--authkey", $authkey) `
    -NoNewWindow -Wait -PassThru