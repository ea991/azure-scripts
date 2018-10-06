#Create a route, create and add route to route table, apply route table to a subnet
$route = New-AzureRmRouteConfig -Name RouteToBackEnd -AddressPrefix 192.168.2.0/24 `
  -NextHopType VirtualAppliance -NextHopIpAddress 192.168.0.4
$routeTable = New-AzureRmRouteTable -ResourceGroupName TestRG -Location 'West US' `
  -Name UDR-FrontEnd -Route $route
$vNet = Get-AzureRmVirtualNetwork -ResourceGroupName TestRG -Name TestVNet
Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vNet -Name FrontEnd `
  -AddressPrefix 192.168.1.0/24 -RouteTable $routeTable