param (
    [string]$SignalFile = "C:\Windows\Temp\broadcast_received",
    [int]$Interval = 30,
    [int]$Port = 5000
)

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.PrefixOrigin -eq "Dhcp"}).IPAddress
$message = "${ip}"

$udpClient = New-Object System.Net.Sockets.UdpClient
$udpClient.EnableBroadcast = $true

$endpoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Broadcast, $Port)

$bytes = [System.Text.Encoding]::UTF8.GetBytes($message)

while (-not (Test-Path $signalFile)) {
	$udpClient.Send($bytes, $bytes.Length, $endpoint)
	Write-Host "Broadcast sent to 255.255.255.255 on port $Port"

	Start-Sleep -Seconds $Interval
}

$udpClient.Close()
Write-Output "Signal received, broadcast ended."

