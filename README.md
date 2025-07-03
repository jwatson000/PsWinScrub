```
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
$url = 'https://raw.githubusercontent.com/jwatson000/PsWinScrub/refs/heads/main/PsWinScrub.ps1'
(Invoke-WebRequest $url).Content > PsWinScrub.ps1
.\PsWinScrub.ps1
```
