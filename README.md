Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
winget install git.git
git clone https://github.com/jwatson000/PsWinScrub.git
. ./PsWinScrub/PsWinScrub.ps1
SetupPC
