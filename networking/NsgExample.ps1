#Network Security Groups (NSG)
#Set variables for the Resource Group and the location
$RGName = 'contoso-iaas'
$Location = 'East US'

#Create a new rule to allow traffic from teh Internet to port 443
$NSGRule1 = New-AzureRmNetworkSecurityRuleConfig -Name 'WEB' -Direction Inbound -Priority 100 `
  -Access Allow -SourceAddressPrefix 'INTERNET' -SourcePortRange '*' `
  -DestinationAddressPrefix '*' -DestinationPortRange '443' -Protocol Tcp

#Create a new NSG using the Rule created
New-AzureRmNetworkSecurityGroup -Name "NSGFrontEnd" -Location $Location -ResourceGroupName $RGName -SecurityRules $NSGRule1 #could use array of rules or separate by comma, e.g. rule1, rule2

$NSG = Get-AzureRmNetworkSecurityGroup -Name "NSGFrontEnd" -ResourceGroupName $RGName

#Add rule to existing NSG to allow RDP
Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG -name 'RDP' -Direction Inbound -Priority 101 `
  -Access Allow -SourceAddressPrefix 'INTERNET' -SourcePortRange '*' `
  -DestinationAddressPrefix '*' -DestinationPortRange '3389' -Protocol Tcp
Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $NSG #Apply the change to the in-memory object

#Remove a rule
Get-AzureRmNetworkSecurityGroup -name "NSGFrontEnd" -ResourceGroupName $RGName | Remove-AzureRmNetworkSecurityRuleConfig -Name 'RDP' |
  Set-AzureRmNetworkSecurityGroup

#NSG must be same region as the resource
#Associate a NSG to a Virtual Machine NIC, usually we don't do this and associate to Subnets
$NICName = 'vm-w16-tst914'
$NIC = Get-AzureRmNetworkInterface -name $NICName -ResourceGroupName $RGName
$nic.NetworkSecurityGroup = $NSG
Set-AzureRmNetworkInterface -NetworkInterface $NIC

#Remove a NSG from a VM NIC
$nic.NetworkSecurityGroup = $null
Set-AzureRmNetworkInterface -NetworkInterface $NIC

#Associate a NSG to a subnet
$vNetName = 'contoso-vnet-azure'
$vNetRG = 'contoso-iaas'
$SubnetNumber = 'azure-subnet-1'
$vNet = Get-AzureRmVirtualNetwork -name $vNetName -ResourceGroupName $vNetRG
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vNet -name $SubnetNumber `
  -AddressPrefix 10.0.1.0/24 -NetworkSecurityGroup $NSG
Set-AzureRmVirtualNetwork -VirtualNetwork $vNet

#Remove a NSG from the subnet
$vNet = Get-AzureRmVirtualNetwork -name $vNetName -ResourceGroupName $vNetRG
$vNetSubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vNet -Name $SubnetNumber
$vNetSubnet.NetworkSecurityGroup = $null
Set-AzureRmVirtualNetwork -VirtualNetwork $vNet