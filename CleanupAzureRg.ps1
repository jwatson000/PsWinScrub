param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [switch]$WhatIf
)

# Ensure logged in
if (-not (Get-AzContext)) {
    Connect-AzAccount
}

Write-Host "`nScanning for unused resources in resource group: $ResourceGroupName..." -ForegroundColor Cyan

# 1. VMs (we just collect for context, not deleting here)
$vms = Get-AzVM -ResourceGroupName $ResourceGroupName

# 2. Unattached Managed Disks
$disks = Get-AzDisk -ResourceGroupName $ResourceGroupName
$unusedDisks = $disks | Where-Object { $_.ManagedBy -eq $null }

if ($unusedDisks) {
    Write-Host "`nUnattached managed disks:" -ForegroundColor Yellow
    $unusedDisks | ForEach-Object {
        Write-Host "  $($_.Name)"
        if (-not $WhatIf) {
            Remove-AzDisk -ResourceGroupName $ResourceGroupName -DiskName $_.Name -Force
        }
    }
}

# 3. Unattached NICs
$nics = Get-AzNetworkInterface -ResourceGroupName $ResourceGroupName
$unusedNics = $nics | Where-Object { $_.VirtualMachine -eq $null }

if ($unusedNics) {
    Write-Host "`nUnattached network interfaces:" -ForegroundColor Yellow
    $unusedNics | ForEach-Object {
        Write-Host "  $($_.Name)"
        if (-not $WhatIf) {
            Remove-AzNetworkInterface -ResourceGroupName $ResourceGroupName -Name $_.Name -Force
        }
    }
}

# 4. Unassociated Public IPs
$publicIPs = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName
$unusedIPs = $publicIPs | Where-Object { $_.IpConfiguration -eq $null }

if ($unusedIPs) {
    Write-Host "`nUnassociated public IP addresses:" -ForegroundColor Yellow
    $unusedIPs | ForEach-Object {
        Write-Host "  $($_.Name)"
        if (-not $WhatIf) {
            Remove-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $_.Name -Force
        }
    }
}

# 5. Unused NSGs
$nsgs = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName
$unusedNsgs = $nsgs | Where-Object {
    ($_.NetworkInterfaces.Count -eq 0) -and ($_.Subnets.Count -eq 0)
}

if ($unusedNsgs) {
    Write-Host "`nUnused network security groups:" -ForegroundColor Yellow
    $unusedNsgs | ForEach-Object {
        Write-Host "  $($_.Name)"
        if (-not $WhatIf) {
            Remove-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $_.Name -Force
        }
    }
}

# 6. Empty Storage Accounts
$storageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
foreach ($account in $storageAccounts) {
    $ctx = $account.Context
    $containers = Get-AzStorageContainer -Context $ctx
    $fileshares = Get-AzStorageShare -Context $ctx
    if ($containers.Count -eq 0 -and $fileshares.Count -eq 0) {
        Write-Host "`nEmpty storage account: $($account.StorageAccountName)" -ForegroundColor Yellow
        if (-not $WhatIf) {
            Remove-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $account.StorageAccountName -Force
        }
    }
}

Write-Host "`nCleanup complete." -ForegroundColor Green
