# ログイン

# 1.認証情報の取得
Get-AzurePublishSettingsFile

# 2.取得ＩＮＦＯの取り込み
Import-AzurePublishSettingsFile -PublishSettingsFile "C:\Users\英雄\Downloads\Visual Studio Professional-9-30-2016-credentials.publishsettings"

# 3.アカウント一覧
Get-AzureAccount

# Id                                              Type Subscriptions                        Tenants
# --                                              ---- -------------                        -------
# DCB894555B06CF3A54580EBB24061B9A1B080705 Certificate 18540eac-ce4f-4eec-ad12-db84df12bd86

# 4.サブスクリプション情報取得
# PS C:\Users\英雄> 
#

Get-AzureSubscription

# SubscriptionId            : 18540eac-ce4f-4eec-ad12-db84df12bd86
# SubscriptionName          : Visual Studio Professional
# Environment               : AzureCloud
# DefaultAccount            : DCB894555B06CF3A54580EBB24061B9A1B080705
# IsDefault                 : True
# IsCurrent                 : True
# TenantId                  :
# CurrentStorageAccountName :
#===================================================================================================

# PS C:\Users\英雄> Add-AzureRmAccount
#
# $TenantId = "0a1f822a-a564-4ccf-bab3-bf1ea5c8bcfa"
# $SubscriptionId = "18540eac-ce4f-4eec-ad12-db84df12bd86"
# Add-AzureRmAccount -Tenant $TenantId -SubscriptionId $SubscriptionId
Add-AzureRmAccount
#
#

# Environment           : AzureCloud
# Account               : h-hasimoto@st-grp.co.jp
# TenantId              : 0a1f822a-a564-4ccf-bab3-bf1ea5c8bcfa
# SubscriptionId        : 18540eac-ce4f-4eec-ad12-db84df12bd86
# SubscriptionName      : Visual Studio Professional
# CurrentStorageAccount :

#===================================================================================================
# PS C:\Users\英雄> Get-AzureRmLocation | sort Location | Select Location

Get-AzureRmLocation | sort Location | Select Location

# Location
# --------
# brazilsouth
# canadacentral
# canadaeast
# centralus
# eastasia
# eastus
# eastus2
# japaneast
# japanwest
# northcentralus
# northeurope
# southcentralus
# southeastasia
# uksouth
# ukwest
# westcentralus
# westeurope
# westus
# westus2
#===================================================================================================
# https://azure.microsoft.com/ja-jp/documentation/articles/virtual-machines-windows-ps-create/
# https://azure.microsoft.com/ja-jp/documentation/articles/virtual-machines-windows-cli-ps-findimage/

$locName = "westus2"
$rgName = "ResouceGroup1"

New-AzureRmResourceGroup -Name $rgName -Location $locName

#
#ResourceGroupName : mygroup1
#Location          : japaneast
#ProvisioningState : Succeeded
#Tags              :
#ResourceId        : /subscriptions/18540eac-ce4f-4eec-ad12-db84df12bd86/resourceGroups/mygroup1

#===================================================================================================
$stName = "storage5413"
Get-AzureRmStorageAccountNameAvailability $stName

#NameAvailable Reason Message
#------------- ------ -------
#         True

#===================================================================================================
$storageAcc = New-AzureRmStorageAccount `
 -ResourceGroupName $rgName `
 -Name $stName `
 -SkuName "Standard_LRS" `
 -Kind "Storage" `
 -Location $locName `

#===================================================================================================
# ネットワークセキュリティグループ

$nsgName = "myNetworkSecGroup1"
$nsg = New-AzureRmNetworkSecurityGroup -Location $locName -Name $nsgName -ResourceGroupName $rgName

# 変更するネットワークセキュリティグループを取得
#$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName

$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName

#$rule = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name 'localnet' -Access Allow -Protocol * -Direction Inbound -Priority 110 -SourceAddressPrefix VirtualNetwork -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
#$rule = Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "ssh" -Access Allow -Protocol * -Direction Inbound -Priority 210 -SourceAddressPrefix * -SourcePortRange 443 -DestinationAddressPrefix * -DestinationPortRange 22
$rule = Add-AzureRmNetworkSecurityRuleConfig `
 -NetworkSecurityGroup $nsg `
 -Name "default-allow-ssh" `
 -Priority 1000 `
 -Access Allow `
 -Protocol "TCP" `
 -Direction Inbound `
 -SourceAddressPrefix * `
 -SourcePortRange * `
 -DestinationAddressPrefix * `
 -DestinationPortRange 22

 $rule = Add-AzureRmNetworkSecurityRuleConfig `
 -NetworkSecurityGroup $nsg `
 -Name "tunnel-ssh" `
 -Priority 1001 `
 -Access Allow `
 -Protocol "TCP" `
 -Direction Inbound `
 -SourceAddressPrefix * `
 -SourcePortRange 443 `
 -DestinationAddressPrefix * `
 -DestinationPortRange 22

# ルールをNSGに反映する
$nsg = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $rule
#===================================================================================================
$subnetName = "mysubnet1"
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix 10.0.0.0/24

$vnetName = "myvnet1"

$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet
$vnet = Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName -NetworkSecurityGroup $nsg -AddressPrefix "10.0.0.0/24"
$vnet = Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
#===================================================================================================
$compName1 = "testdfs1"
$ipName1 = "myIPaddress1"
$domainlabel1  = $compName1 +  "zz5413"
$pip1 = New-AzureRmPublicIpAddress -Name $ipName1 -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic -DomainNameLabel $domainlabel1
$nicName1 = "mynic1"
$nic1 = New-AzureRmNetworkInterface -Name $nicName1 -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip1.Id

$compName2 = "testssh1"
$ipName2 = "myIPaddress2"
$domainlabel2  = $compName2 + "zz5413"
$pip2 = New-AzureRmPublicIpAddress -Name $ipName2 -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic -DomainNameLabel $domainlabel2
$nicName2 = "mynic2"
$nic2 = New-AzureRmNetworkInterface -Name $nicName2 -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip2.Id

#===================================================================================================
$cred = Get-Credential -Message "Type the name and password of the local administrator account."
# vmadmin
# vmAd1357min00

$vmName1 = "TESTDFS1"
$vm1 = New-AzureRmVMConfig -VMName $vmName1 -VMSize "Basic_A0"
$vm1 = Set-AzureRmVMOperatingSystem -VM $vm1 -Windows -ComputerName $compName1 -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm1 = Set-AzureRmVMSourceImage -VM $vm1 -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
$vm1 = Add-AzureRmVMNetworkInterface -VM $vm1 -Id $nic1.Id

#
$blobPath1 = "vhds/WindowsVMosDisk.vhd"
$osDiskUri1 = $storageAcc.PrimaryEndpoints.Blob.ToString() + $blobPath1
$diskName1 = "windowsvmosdisk"
$vm1 = Set-AzureRmVMOSDisk -VM $vm1 -Name $diskName1 -VhdUri $osDiskUri1 -CreateOption fromImage

New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm1

# RequestId IsSuccessStatusCode StatusCode ReasonPhrase
# --------- ------------------- ---------- ------------
#                         True         OK OK

Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName1 | Select ResourceGroupName,Name
#====================================================================================================
# http://statemachine.hatenablog.com/entry/2015/07/06/183650

$vmName2 = "TESTSSH1"
$vm2 = New-AzureRmVMConfig -VMName $vmName2 -VMSize "Basic_A0"
$vm2 = Set-AzureRmVMOperatingSystem -VM $vm2 -Linux -ComputerName $compName2 -Credential $cred
$vm2 = Set-AzureRmVMSourceImage -VM $vm2 -PublisherName Canonical -Offer UbuntuServer -Skus 16.10-DAILY -Version "latest"
$vm2 = Add-AzureRmVMNetworkInterface -VM $vm2 -Id $nic2.Id
#
$blobPath2 = "vhds/UbuntuVMosDisk.vhd"
$osDiskUri2 = $storageAcc.PrimaryEndpoints.Blob.ToString() + $blobPath2
$diskName2 = "ubuntuvmosdisk"
$vm2 = Set-AzureRmVMOSDisk -VM $vm2 -Name $diskName2 -VhdUri $osDiskUri2 -CreateOption fromImage

New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm2

Set-AzureEndpoint -Name "web" -LocalPort 22 -VM $vm2 -PublicPort 443 -Protocol "tcp"

#===================================================================================================
# https://azure.microsoft.com/ja-jp/documentation/articles/virtual-machines-windows-ps-manage/

# ◇仮想マシンを起動する

Start-AzureRmVM -ResourceGroupName $rgName -Name $vmName

# ◇仮想マシンを停止する
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force

Stop-AzureRmVM -ResourceGroupName $rgName -Name "TESTDFS1" -Force
Stop-AzureRmVM -ResourceGroupName $rgName -Name "TESTSSH1" -Force

# ◇仮想マシンを再起動する
Restart-AzureRmVM -ResourceGroupName $rgName -Name $vmName

# ◇仮想マシン削除する
# Remove-AzureRmVM -ResourceGroupName $rgName ?Name $vmName

Remove-AzureRmResourceGroup -Name $rgName
#===================================================================================================
基本操作

◇仮想マシンをリストアップする
Get-AzureRmVM

◇仮想マシンを起動する
Start-AzureVM -Name computerName -ServiceName serviceName

◇仮想マシンを停止する
Stop-AzureRmVM -Name computerName -ServiceName serviceName -Force

#===================================================================================================
foreach ($node in $( Get-AzureRmVm ) ) {
	Write-Host $node.Name 
	Start-Job -ScriptBlock { 
		param($node) 
		Stop-AzureRmVM -ResourceGroupName $rgName -Name $node.Name -Force 
	} -Arg $node 
} 

#===================================================================================================

#===================================================================================================

#===================================================================================================
