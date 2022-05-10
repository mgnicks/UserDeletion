# UserDeletion v0.5

Function BulkDeletion {

Function Get-FileName($initialDirectory)

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.Filter = "csv (*.csv) | *.csv"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.FileName

}
Write-host "Getting list of Users..."

$inputfile = Get-FileName
$Users = import-csv -Path $inputfile -header fname,lname

# Check to see if the UserDeletions Folder exists already. If not then create it.
$PathFound = Test-Path C:\UserDeletions\

If ($PathFound -ne "TRUE") 
    {
      Write-Host "This folder does not exist. We will create it now..."
      mkdir C:\UserDeletions
      sleep 5
      $PathFound = "C:\UserDeletions\"
    }
    else 
    {
      write-host "This folder already exists. We will use it to store the logs"
      $PathFound = "C:\UserDeletions\"
    }


# Import the AD Module
Import-module ActiveDirectory

 # Find the AD users
 Write-Host "Locating AD Usernames and gathering information and exporting to their log file"

 ForEach ($User in $Users) {
     $Filter = "givenName -eq ""$($user.fname)"" -and sn -eq ""$($user.lname)""" 
     $username = Get-ADUser -Filter $Filter -Properties *
     $id = $username.SamAccountName
     $AddressBookValue = $username.msExchHideFromAddressLists
     $UserIsDisabled = $username.enabled | fl
    
     $LogFile = ("$PathFound" + "$id-" + "Deletion.log")
     Out-File -FilePath $LogFile

     # Export the list of groups that this user is a member of.
    $GroupMembership = Get-ADPrincipalGroupMembership -identity $id | Where-object {$_.name -ne "Domain Users"} | sort name | select name | Out-File $LogFile
    
    if ($AddressBookValue -eq "TRUE") {
    echo "$id is hidden from Address Book. Current entry is is $AddressBookValue" >> $LogFile } else {
    echo "$id is not been hidden from Address Book. Current entry is $AddressBookValue" >> $LogFile}
    echo "Checking if $id account is disabled..."
    if ($Username.Enabled -eq "TRUE") {
        echo "$id is enabled. Disabling the account now..."
        echo "$id is Enabled" >> $LogFile
        Disable-ADAccount $id |where {$username.enabled -eq $TRUE}
        echo "$id has now been disabled" >> $LogFile
        echo "$id account disabled."
    } else {
        echo "$id is already disabled" >> $LogFile
        echo "$id account already disabled."
    }
   
   # Begin user deletion process
   if ($AddressBookValue -eq "FALSE") {
    Set-ADUser $id -replace @{msExchHideFromAddressLists=$true}
    }
    echo "$id has now been hidden from address book" >> $Logfile 

    Write-host "We are now removing the account from their groups"

if (Test-Path $Logfile) { 
  Get-ADPrincipalGroupMembership -Identity $id | 
        ? {$_.Name -ne "Domain Users"} |
        % {Remove-ADPrincipalGroupMembership -Confirm:$false -Identity $id -MemberOf $_}
         echo "$id has now been removed from all groups" >> $Logfile
        } else {
        echo "$logfile doesn't exist for $id"
        }
  }


# New citrix session check for active sessions - not checked

# Connect to CDC server and check for valid sessions 
Enter-PSSession cdc01
asnp citrix*
$AssignedDesktop = get-brokerdesktop | select HostedMachineName, SessionUserName | where { $_.SessionUserName -eq "RA\$username" }
echo $AssignedDesktop >> $LogFile

# End of new citrix session checking.

} # End of BulkDeletion Function


# Begining of SingleDeletion Function
function SingleDeletion {

# Import the AD Module
Import-module ActiveDirectory

#Get the name of the user from command-line entry - most likely would be copy and paste

$fname = Read-Host "Please provide the users first name"
$lname = Read-Host "Please provide the users last name"

# Find the username Using the first name and last name provided above
# $username = Get-ADUser -Filter 'GivenName -eq $fname -and sn -eq $lname' -properties SamAccountName | select -ExpandProperty SamAccountName

$username = Get-ADUser -Filter 'GivenName -eq $fname -and sn -eq $lname' -Properties *
$id = $username.SamAccountName
$AddressBookValue = $username.msExchHideFromAddressLists
$UserIsDisabled = $username.enabled | fl

# Check to see if the UserDeletions Folder exists already. If not then create it.
$PathFound = Test-Path C:\UserDeletions\

If ($PathFound -ne "TRUE") {
    Write-Host "This folder does not exist. We will create it now..."
    mkdir C:\UserDeletions
    sleep 5
    $PathFound = "C:\UserDeletions\"
    }
    else {
    write-host "This folder already exists. We will use it to store the logs"
    $PathFound = "C:\UserDeletions\"
    }
    
# This variable will be used to create CSV file that contains a list of all of the groups that this 
# user is a member of. Eventually it will contain all of the data from the user account.

$LogFile = ("$PathFound" + "$id-" + "Deletion.log")


# Export the list of groups that this user is a member of.
$GroupMembership = Get-ADPrincipalGroupMembership -identity $id | Where-object {$_.name -ne "Domain Users"} | sort name | select name >> $LogFile



################

echo "Begining the user deletion process"

# Checking if user account is disabled and adding it to the log file

echo "Checking if account is disabled... >> $LogFile"
if ($Username.Enabled -eq "TRUE") {
echo "$id is Enabled" >> $LogFile
Disable-ADAccount $id |where {$username.enabled -eq $TRUE}
echo "$id has now been disabled" >> $LogFile
 } else {
echo "$id is already disabled" >> $LogFile
}


# Hide the user from the address list
Set-ADUser $id -Add @{msExchHideFromAddressLists="TRUE"}

# Removes the user from the groups that they are found in - Domain Users cannot be removed.

Get-ADPrincipalGroupMembership -Identity $id | 
        ? {$_.Name -ne "Domain Users"} |
        % {Remove-ADPrincipalGroupMembership -Confirm:$false -Identity $id -MemberOf $_}


} # End of Single Deletion


# User Deletion Menu

function Show-Menu {
    param (
        [string]$Title = 'User Deletion Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' for CSV import. This will open a window to choose the CSV file"
    Write-Host "2: Press '2' for Manual Entry."
    Write-Host "Q: Press 'Q' to quit."
}

do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    '1' {
    BulkDeletion
    } '2' {
    SingleDeletion
    }
   }
    pause
 }
 until ($selection -eq 'q')