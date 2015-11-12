Remove-Module PoshStack
Import-Module PoshStack
Clear
Get-OpenStackLoadBalancer -Account rackiad 
$LBID = New-Object -TypeName ([net.openstack.Providers.Rackspace.Objects.LoadBalancers.LoadBalancerId]) -ArgumentList "103943"
#Write-Host $LBID
Get-OpenStackLoadBalancer -Account rackiad -LBID $LBID
Get-OpenStackLBConnectionLogging -Account rackiad -LBID $LBID
Get-OpenStackLBHealthMonitor -Account rackiad -LBID $LBID
Get-OpenStackLBAlgorithmList -Account rackiad
Get-OpenStackLBAllowedDomainList -Account rackiad
Get-OpenStackLBNode -Account rackiad -LBID $LBID 
Get-OpenStackLBProtocolList -Account rackiad
Get-OpenStackLBThrottleList -Account rackiad -LBID $LBID
Get-OpenStackLBVirtualAddressList -Account rackiad -LBID $LBID
New-OpenStackLoadBalancer -Account rackiad -LBConfig