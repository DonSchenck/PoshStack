Import-Module PoshStack

$myMetadata = @{}
$myMetadata.Add("Hello","World")
$myMetadata.Add("Foo","Bar")
#New-OpenStackCloudQueue -Account rackiad -QueueName "queuename" -RegionOverride IAD
#Get-OpenStackCloudQueue -Account rackiad -RegionOverride IAD
#Set-OpenStackCloudQueueMetadata -Account rackiad -QueueName "queuename" -Metadata $myMetadata -RegionOverride IAD
#$md = Get-OpenStackCloudQueueMetadata -Account rackiad -QueueName "queuename" -RegionOverride IAD
#ForEach($metadata in $md) {
#    Write-Host $metadata.keys
#    Write-Host $metadata.Values
#}
$TTL = New-Object ([TimeSpan]) 4,0,0
$listofmsgs = @()
$listofmsgs += "Hello world"
$listofmsgs += "Second message"
Write-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename" -TTL $TTL -ListOfMessages $listofmsgs -RegionOverride IAD
$readmessages = Read-OpenStackCloudQueueMessage -Account rackiad -Queuename "queuename" -TTL $TTL -GracePeriod $TTL -NumberToRetrieve 4 -RegionOverride IAD
Write-Host $readmessages.Messages.Count
Get-OpenStackCloudQueueClaim -Account rackiad -Claim $readmessages -QueueName "queuename"
ForEach($m in $readmessages.Messages) {
      Write-Host "body " $m.Body.ToString()
}


$listOfMessages = Get-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename"

$messageIDList = @()
ForEach($cqm in $listOfMessages) {
    $messageIDList += $cqm.Id

    Write-Host "MessageID: " $cqm.Id
}

Get-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename" -MessageIDList $messageIDList

#Remove-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename" -ListOfMessageId
Get-OpenStackCloudQueueHome -Account rackiad

Confirm-OpenStackCloudQueueExists -Account rackiad -QueueName "queuename"

Get-OpenStackCloudQueueStatistics -Account rackiad -QueueName "queuename"

$bunchOfMessages = Read-OpenStackCloudQueueMessage -Account rackiad -QueueName "queuename" -TTL $TTL -GracePeriod $TTL -NumberToRetrieve 100
Write-Host "Number of message read: " $bunchOfMessages.Messages.Count

