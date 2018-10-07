#Create a Load Balancer with NAT Rule and Load Balancer
$RGName = "contoso-iaas"
$vNetName = "contoso-vnet-azure"
$vNet = Get-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $RGName
$targetSubnet = $vNet.Subnets[0]
$loc = "eastus"

#Create internal IP address
$frontEndIP = New-AzureRmLoadBalancerFrontendIpConfig - New-AzureRmLoadBalancerFrontendIpConfig LB-FrontEnd -PrivateIpAddress 10.0.3.5 `
  -SubnetId $targetSubnet.Id

#Create external IP address
$pipLB = New-AzureRmPublicIpAddress -ResourceGroupName $RGName -Name "vipLB" `
  -Location $loc -AllocationMethod Dynamic -DomainNameLabel "viplb"
$frontEndIP = New-AzureRmLoadBalancerFrontendIpConfig -Name LB-FrontEnd -PublicIpAddressId $pipLB.Id

#Create external IP address and assign directly to a VM
$pip = New-AzureRmPublicIpAddress -ResourceName $RGName -Name "vip1" `
  -Location $loc -AllocationMethod Dynamic -DomainNameLabel $vmname.ToLower()
$nic = New-AzureRmNetworkInterface -Force -Name ('nic' + $vmname) -ResourceGroupName $RGName `
  -Location $loc -SubnetId $subnetID -PrivateIpAddress 10.7.115.13 -DnsServer 10.7.115.13 `
  -PublicIpAddressId $pip.Id

#NAT rules (port forwarding)
$inboundNATRule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP1" -FrontendIpConfiguration $frontEndIP `
  -Protocol Tcp -FrontendPort 3441 -BackendPort 3389
$inboundNATRule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP2" -FrontendIpConfiguration $frontEndIP `
-Protocol Tcp -FrontendPort 3442 -BackendPort 3389

#Load Balancer config settings
$beAddressPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "LB-Backend" #this is just a name that is used when associating the NIC
$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name "HealthProbe" -RequestPath "index.aspx" `
  -Protocol Http -Port 80 -IntervalInSeconds 15 -ProbeCount 2
$lbRule = New-AzureRmLoadBalancerRuleConfig -Name "HTTP" -FrontendIpConfiguration $frontEndIP `
  -BackendAddressPool $beAddressPool -Probe $healthProbe -Protocol Tcp `
  -FrontendPort 80 -BackendPort 80 #-LoadDistribution SourceIP

#Create Load Balancer
$nrpLB = New-AzureRmLoadBalancer -ResourceGroupName $RGName -Name "NRP-LB" -Location $loc -FrontendIpConfiguration $frontEndIP `
  -InboundNatRule $inboundNATRule1, $inboundNATRule2 `
  -LoadBalancingRule $lbRule -BackendAddressPool $beAddressPool -Probe $healthProbe

#Assign LB configuration when creating NICs
$vmNIC1 = New-AzureRmNetworkInterface -ResourceGroupName $RGName -Name lb-nic1-be -Location $loc `
  -PrivateIpAddress 10.0.3.6 -Subnet $targetSubnet `
  -LoadBalancerBackendAddressPool $nrpLB.BackendAddressPools[0] `
  -LoadBalancerInboundNatRule $nrpLB.InboundNatRules[0] #Use the first NAT Rule1
$vmNIC2 = New-AzureRmNetworkInterface -ResourceGroupName $RGName -Name lb-nic2-be -Location $loc `
  -PrivateIpAddress 10.0.3.7 -Subnet $targetSubnet `
  -LoadBalancerBackendAddressPool $nrpLB.BackendAddressPools[0]
  -LoadBalancerInboundNatRule $nrpLB.InboundNatRules[1] #Use the second NAT Rule2
  #Now just need to add the NICs to a VM configuration and create

  #Add a NAT Rule to an existing NiC rather than at creation time
  $nic = Get-AzureRmNetworkInterface -ResourceGroupName $RGName -Name "<nic name>" #how to get a NIC
  $nic.IpConfigurations[0].LoadBalancerInboundNatRules.Add($nrpLB.InboundNatRules[0])
  Set-AzureRmNetworkInterface -NetworkInterface $nic

  #Add NAT rule to an existing Load Balancer
  $nrpLB | Add-AzureRmLoadBalancerInboundNatRuleConfig -Name "RDP3" -FrontendIpConfiguration $frontEndIP `
    -Protocol Tcp -FrontendPort 3443 -BackendPort 3389


