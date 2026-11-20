param([Parameter(Mandatory)][ValidateSet('lead','helper')][string]$Role)
$ErrorActionPreference = 'Stop'
$requiredLogin = @{lead='dvaknin001';helper='hipopdog19-wq'}[$Role]
$login = gh api user --jq .login
if ($LASTEXITCODE -ne 0 -or $login -ne $requiredLogin) { throw "Sign in to GitHub CLI as $requiredLogin first." }
$python = (Get-Command python.exe).Source
$pythonw = Join-Path (Split-Path $python) 'pythonw.exe'
if (!(Test-Path -LiteralPath $pythonw)) { throw 'Install Python 3 with pythonw.exe.' }
codex login status
if ($LASTEXITCODE -ne 0) { throw 'Sign in to Codex CLI on this PC first.' }
$target = Join-Path $env:LOCALAPPDATA "PJD-Relay\$Role"
New-Item -ItemType Directory -Path $target -Force | Out-Null
$script = Join-Path $target 'relay.py'
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'relay.py') -Destination $script
$taskName = "PJD mailbox - $Role"
$action = New-ScheduledTaskAction -Execute $pythonw -Argument ('"{0}" {1} poll' -f $script,$Role) -WorkingDirectory $target
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 6)
$principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Output "Started $taskName. Local status is in $target\health.json."
