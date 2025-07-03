
param (
	[Parameter(Mandatory)][ValidateSet('HordeAgent','Developer')]
  [string]$HostType,
  [switch]$WhatIf
)

function SetDefaultBrowser() {
	$shell = New-Object -ComObject WScript.Shell
	Start-Process ms-settings:defaultapps
	start-sleep 1; 1..4 | % {$shell.SendKeys('{TAB}')}; 
	start-sleep 1; $shell.sendKeys('Brave');
	start-sleep 1; $shell.SendKeys('{TAB}'); $shell.SendKeys('{ENTER}'); 
	start-sleep 1; $shell.SendKeys('{ENTER}'); 
	start-sleep 1
	$shell.SendKeys('%{F4}')
}

function SetTerminalPreviewPowershell() {

  $applocal = "$Home\AppData\Local"

  $guid = "{574e775e-4f2a-5b96-ac1e-a2962a402336}"

  foreach ($appn in @('WindowsTerminalPreview', 'WindowsTerminal')) {
    $fn = "$AppLocal\Packages\Microsoft.${appn}_8wekyb3d8bbwe\LocalState\settings.json"
    write-host "Checking $appn @$fn"
    if (!(Test-Path $fn)) { write-host "not installed at $fn"; return}
    $j = get-content $fn | convertfrom-json

    foreach ($p in $j.profiles.list) {
      if ($p.guid -eq $guid) {
        write-host "discovered $($p.source)"
        $j.defaultProfile = $guid
        #$j | convertto-json -Depth 10 > $fn
      }
    }
  }  
}

function Set-EnableRDP() {
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "updateRDStatus" -Value 1
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "updateRDStatus" -Value 1


  Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
}

function Set-TaskbarPins() {
  $f="$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\"
  # https://superuser.com/questions/1193985/command-line-code-to-pin-program-to-taskbar-windows-10
}

function Set-EnableVM() {
  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
}


function Set-DisableWindowsSpotlight() {
  # Define the registry path
  $RegistryPath = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"

  # Create the registry key if it doesn't exist
  if (-not (Test-Path $RegistryPath)) {
    New-Item -Path $RegistryPath -Force
  }

  # Set the value of DisableWindowsSpotlightFeatures to 1
  Set-ItemProperty -Path $RegistryPath -Name "DisableWindowsSpotlightFeatures" -Value 1
}

function Set-DisableWindowsTabloidSlime() {
  Get-AppxPackage *WebExperience* | Remove-AppxPackage
  stop-process -name explorer
}

function Set-EnableDeveloperMode() {
	reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
}


function Set-EnableClipboardHistory {
	Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 1
}

$AppsByHostType = @{
 All =  @(
    'Microsoft.PowerShell',
    'Microsoft.Sysinternals',
    'Microsoft.DotNet.DesktopRuntime.6', #required for powertoys
    'Microsoft.PowerToys',
    'Brave.Brave',
    'pulsejet.edgeandbingdeflector', # unclear if this actually works
    'Microsoft.WindowsTerminal.Preview',
    'WireGuard.WireGuard'
  ) 
  HordeServer =  @()
  HordeClient = @()
  Developer = @(
    @(
      '9NP355QT2SQB', # azure vpn client
      'Microsoft.VisualStudioCode',
      'Microsoft.VisualStudioCode.CLI',
      'JetBrains.Rider',
      'AgileBits.1Password',
      'AgileBits.1Password.CLI',
      #'Microsoft.WSL',
      'Valve.Steam',
      'Valve.SteamCMD',
      'Obsidian.Obsidian',
      '9PLDPG46G47Z', # xbox insider hub
      'Perforce.P4V',
      'Araxis.Merge',
      'NickeManarin.ScreenToGif',
      'Zoom.Zoom',
      'Microsoft.VisualStudio.Professional',
      'Microsoft.WindowsSDK.10.0.26100',
      'Microsoft.Sysinternals.RDCMan',
      'EpicGames.EpicGamesLauncher',
      'Python.Python.3.13'
    )
  )
}


function Set-InstallDeveloperApps() {
	$wapps = Get-InstallDeveloperApps
	$WingetArgs = '--disable-interactivity --accept-source-agreements --accept-package-agreements'
	foreach ($wapp in $wapps) {
		winget install $wapp ($WingetArgs -split ' ')
	}
}

function Set-InstallApps() {
	param (
		$wapps
 	)
 
  write-host ":: Installing apps: [$($wapps -join ',')]"
	$WingetArgs = '--disable-interactivity --accept-source-agreements --accept-package-agreements'
	foreach ($wapp in $wapps) {
    write-host ":: Installing app : $wapp" -ForegroundColor Cyan
    if (!$WhatIf) { winget install $wapp ($WingetArgs -split ' ') }
	}
}



function Set-UpdatePc() {
  #wuauclt.exe /updatenow
  #UsoClient.exe ScanInstallWait
  Install-Module PSWindowsUpdate -Force -Confirm:$False
  Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
}


function Get-AppListForHosttype() {
  param($HostType)

  $All = $AppsByHostType['All']
  $Other = $AppsByHostType[$HostType]

  return $All + $Other

  
}


function SetupPC($HostType) {

  $curname = hostname
  $name = read-host ":: Computer name? [ENTER] for default ($Curname)"
  if ($name -and ($name -ne $curname)) { 
    write-host ":: Renaming computer to [$name]"
    if (!$WhatIf) { rename-computer $name }
  } 

  if (!$WhatIf) {
    # remove tabloid slime
    Get-AppxPackage *WebExperience* | Remove-AppxPackage
    
    # disable search suggestions
    New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force
    New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -PropertyType DWORD -Value 0

    # disable uac
    Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0

    # disable windows spotlight
    $RegistryPath = "HKCU:\Software\Policies\Microsoft\Windows\CloudContent"
    if (-not (Test-Path $RegistryPath)) {    New-Item -Path $RegistryPath -Force  }
    Set-ItemProperty -Path $RegistryPath -Name "DisableWindowsSpotlightFeatures" -Value 1

    # disable windows start menu web search
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord

    stop-process -name explorer # flush out the old crap
    
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
    
    # set developer mode
    reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /t REG_DWORD /f /v "AllowDevelopmentWithoutDevLicense" /d "1"
  }

  Set-InstallApps (Get-AppListForHosttype $HostType)
  
  if (!$WhatIf) {
    SetTerminalPreviewPowershell
    
    Set-EnableRDP

    # enable SSH 
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    New-NetFirewallRule -Name sshd -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

    Set-TaskbarPins
    Set-EnableVM
    set-EnableClipboardHistory
  }


# todo: potentially use 1password cli/sdk to login to things like obsidian
# todo: configure individual apps settings (vscode, etc...)
# todo: vscode add extensions: powershell, dotnet, ...

# todo: pin apps to taskbar 'C:\Users\JohnWatson\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\'
# todo: apply Brave bookmarks and backup to git
# todo: add Brave extensions (1Passwd, Adguard? ,Proton?)

}

SetupPc $HostType
