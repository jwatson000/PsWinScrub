```
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
(Invoke-WebRequest 'https://raw.githubusercontent.com/jwatson000/PsWinScrub/refs/heads/main/PsWinScrub.ps1').Content > PsWinScrub.ps1
.\PsWinScrub.ps1
```
