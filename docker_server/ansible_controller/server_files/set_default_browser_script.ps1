  # Changeing default browser for Windows 11 only #
  if ($env:OS -ne 'Windows_NT') { throw 'This script runs on Windows only' }
  Stop-Process -ErrorAction Ignore -Name SystemSettings
  Start-Process ms-settings:defaultapps
  $ps = Get-Process -ErrorAction Stop SystemSettings
  do {
    Start-Sleep -Milliseconds 100
    $ps.Refresh()
  } while ([int] $ps.MainWindowHandle)
  Start-Sleep -Milliseconds 2000
  # Entering key strokes mode.
  $shell = New-Object -ComObject WScript.Shell
  # Tab to the "Set defaults for applications".
  foreach ($i in 1..5) { $shell.SendKeys('{TAB}'); Start-Sleep -milliseconds 100 }
  # Set Firefox as a defaults browser
  $shell.SendKeys("firefox"); Start-Sleep -seconds 1
  
  $shell.SendKeys('{TAB}'); Start-Sleep -milliseconds 200
  $shell.SendKeys('{ENTER}'); Start-Sleep -milliseconds 200
  $shell.SendKeys('{ENTER}'); Start-Sleep -milliseconds 200
  $shell.SendKeys('%{F4}')