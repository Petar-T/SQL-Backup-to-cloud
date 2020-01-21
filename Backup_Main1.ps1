# Check if the SqlServer module is already installed, if not install it
$SQLModuleCheck = Get-Module -ListAvailable SqlServer
if ($SQLModuleCheck -eq $null)
    {
        write-host "SqlServer Module Not Found - Installing"
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Install-Module -Name SqlServer –Scope AllUsers -Confirm:$false -AllowClobber
    }
# Import the SqlServer module
Import-Module SqlServer 


#------------------ parameters to provide
$BackupType = 'Database' # Provide backup Type as 'Database' or 'Log'
$SQLInstance = "localhost"
$LoggingFolder = "D:\SQL_Azure_Backup_Logging\"
$DatabaseList = "master","model","Capstone" # Provide database names seperated by Comma "," e.b. "TestDB1, TestDB2"
#$DatabaseList = "ALL" # Provide database names seperated by Comma "," e.b. "TestDB1, TestDB2"
$storageAccount = "<BlobName>"  
$blobContainer = "<ContainerName>"  
$backupUrlContainer = "https://$storageAccount.blob.core.windows.net/$blobContainer/"  
$credentialName = "<myCredential>"
$BlobAccessKey = "<xyz>" # Provide blob access key for accessing the above BLOB storage e.g. "dxJR6VOGrDyEJJEv5atJPSB7ElhZx+weKhIlWWE/WYuLo8mvM4Bg3mxp8e3FtNuCvvpoO1827gQmsKVemqb8Vyw=="
#------------------




# check if logging folder and files exists
If(!(test-path $LoggingFolder)) { New-Item -ItemType Directory -Force -Path $LoggingFolder}
if(! (Test-Path $LoggingFolder\BackupLog.log ))   { New-Item $LoggingFolder\BackupLog.log -type file }  
if(! (Test-Path $LoggingFolder\BackupErrorLog.Log))   { New-Item $LoggingFolder\BackupErrorLog.Log -type file }  


# Log start
$MsgStart = $(get-date -format yyyy_MM_dd-HH:mm:ss) +  [char]9 + "---  New Backup Task Started! --- , parameters Used: " 
Write-Output  $MsgStart  | Out-File -filePath $LoggingFolder\BackupLog.log  -append



if ($DatabaseList -EQ "ALL") {    $WhereString = '$_.Name -ne "tempdb" -and $_.IsSystemObject -eq $False'    }
elseif ($DatabaseList -EQ "ALLUSER") { $WhereString = '$_.IsSystemObject -eq $False'    } 
else
    {
        $b = '"{0}"' -f ($DatabaseList -join '","')
        $WhereString = '$_.name -in ' + $b    }


    $WhereBlock = [scriptblock]::Create( $WhereString )
    $currentDateTime = get-date -format yyyy-MM-dd-HHmmss


#Get-SqlDatabase -ServerInstance localhost | Where { $_.Name -ne 'tempdb' } | Backup-SqlDatabase
#$DBList=Get-SqlDatabase -ServerInstance localhost | Where { $_.Name -ne 'tempdb' } 
$DBList=Get-SqlDatabase -ServerInstance localhost | Where $WhereBlock | Sort-Object -Property Name


$EncryptionOption = New-SqlBackupEncryptionOption -Algorithm Aes256 -EncryptorType ServerCertificate -EncryptorName "DBBackupEncryptCert"

foreach ($Database in $DBList ) 
  {   
    $BckPath= $backupUrlContainer + $Database.Name +"_" + $currentDateTime + "_" + $BackupType +".bak"

 
TRY 
#{ 
{

$BckMsgStart= $(get-date -format yyyy_MM_dd-HH:mm:ss) + [char]9 + $Database.Name + " backup Started!"
Write-Output $BckMsgStart | Out-File -filePath $LoggingFolder\BackupLog.log  -append

Backup-SqlDatabase -ServerInstance "localhost" -Database $Database.Name -BackupFile $BckPath -SqlCredential "SQLBackups" -CompressionOption On -BackupAction $BackupType -EncryptionOption $EncryptionOption

$BckMsgFinish= $(get-date -format yyyy_MM_dd-HH:mm:ss) + [char]9 + $Database.Name + " backup Completed!"
Write-Output    $BckMsgFinish   | Out-File -filePath $LoggingFolder\BackupLog.log  -append

}
 
CATCH  
{
$MsgErr = $(get-date -format yyyy_MM_dd-HH:mm:ss) + [char]9 + $Database.Name + " backup failed: " + $_.Exception.Message
Write-Output    $MsgErr   | Out-File -filePath $LoggingFolder\BackupErrorLog.Log  -append
} 
} 