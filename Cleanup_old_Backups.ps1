$resourceGroup = "<ResGr>"
$storageAccountName = "<BlobName>"
$containerName = "<ContainerName>"
$DaySpan = 0

# get a reference to the storage account and the context
$storageAccount = Get-AzStorageAccount `
  -ResourceGroupName $resourceGroup `
  -Name $storageAccountName `
  

$ctx = $storageAccount.Context  

$BlobAccessKey = "xyzww=="

$StorageAccountContext = New-AzureStorageContext -storageAccountName $StorageAccountName -StorageAccountKey $BlobAccessKey;
$StorageAccountContext;


# get a list of all of the blobs in the container 
$listOfBLobs = Get-AzStorageBlob -Container $ContainerName -Context $ctx 

# zero out our total
$Size = 0
$NumDel = 0

# this loops through the list of blobs and retrieves the length for each blob
#   and adds it to the total

foreach($blob1 in $listOfBlobs)
{ 
    if  ([datetime]$blob1.LastModified.UtcDateTime -le $now.AddHours(-24*$DaySpan))
    {
     Write-Host "Deleted:"$blob1.name
     Remove-AzureStorageBlob -Container $containerName -Blob $blob1.Name -Context $StorageAccountContext
     $NumDel ++
    }
    else
    {
        $Size = $Size + $blob1.Length
        }
}


# output the blobs and their sizes and the total 

#Write-Host "List of Blobs and their size (length)"
#Write-Host " " 
#$listOfBlobs | select Name, Length
#Write-Host " "
Write-Host "Number of deleted items= " $NumDel
Write-Host "Total Length Remained= " $Size