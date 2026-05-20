# Check if the PSWindowsUpdate is installed
if (Get-Module -ListAvailable | Where-Object { $_.Name -eq "PSWindowsUpdate" }) {
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
    Install-Module -Name PSWindowsUpdate -Force
}