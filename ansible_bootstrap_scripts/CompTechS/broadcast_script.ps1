#####################################
# Broadcast IPv4 Address Script
#
# This script continuously broadcasts the client machine's IPv4 address
# (obtained from the DHCP-assigned interface) over UDP to the broadcast
# address of the local network.
#
# Parameters:
#   -SignalFile [string] : Path to a file whose presence will stop broadcasting.
#                          Default: "C:\Windows\Temp\broadcast_received"
#   -Interval   [int]    : Number of seconds to wait between broadcasts. Default: 40
#   -Port       [int]    : UDP port to broadcast to. Default: 5000
#
# Behavior:
# 1. Retrieves the first IPv4 address assigned via DHCP.
# 2. Prepares a UDP client with broadcast enabled.
# 3. Continuously sends the IP address as a UTF-8 encoded message to
#    255.255.255.255 on the specified port at the specified interval.
# 4. Stops broadcasting when the specified signal file exists.
# 5. Closes the UDP client and outputs a completion message.
#####################################

param (
    [string]$SignalFile = "C:\Windows\Temp\broadcast_received",
    [int]$Interval = 40,
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
    Write-Host "Sending next broadcast in $Interval seconds"

	Start-Sleep -Seconds $Interval
}

$udpClient.Close()
Write-Output "Signal received, broadcast ended."

