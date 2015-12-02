Import-Module PoshStack
$myMetadata = @{}
$myMetadata.Add("Hello","World")
$myMetadata.Add("Foo","Bar")
#New-OpenStackCloudQueue -Account rackiad -QueueName "queuename" -RegionOverride IAD
#Get-OpenStackCloudQueue -Account rackiad -RegionOverride IAD
#Set-OpenStackCloudQueueMetadata -Account rackiad -QueueName "queuename" -Metadata $myMetadata -RegionOverride IAD
$md = Get-OpenStackCloudQueueMetadata -Account rackiad -QueueName "queuename" -RegionOverride IAD
ForEach($metadata in $md) {
    Write-Host $metadata.keys
    Write-Host $metadata.Values
}