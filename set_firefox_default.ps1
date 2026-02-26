# Get the active user safely
$ActiveLine = query user | Select-String 'Active'
$Parts = $ActiveLine -split '\s+'
$CurrentUser = $Parts[1]

# Build full account name
$Machine = $env:COMPUTERNAME
$FullUser = $Machine + '\' + $CurrentUser

# Firefox path
$FirefoxPath = '"C:\Program Files\Mozilla Firefox\firefox.exe"'

# Scheduled task action
$Action = New-ScheduledTaskAction -Execute $FirefoxPath -Argument '-setDefaultBrowser'

# Scheduled task trigger (run once, 5 sec from now)
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(5)

# Register scheduled task for the interactive user
Register-ScheduledTask -TaskName 'FirefoxDefaultPrompt' `
                        -Action $Action `
                        -Trigger $Trigger `
                        -User $FullUser `
                        -RunLevel Highest `
                        -Force