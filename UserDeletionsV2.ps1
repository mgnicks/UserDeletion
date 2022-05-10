# UserDeletion v0.5

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
$date = Get-Date -UFormat "%Y-%m-%d"
$LogFile = ("$PathFound" + $username.displayname + ".$date.log")


# Export the list of groups that this user is a member of.
$GroupMembership = Get-ADPrincipalGroupMembership -identity $id | Where-object {$_.name -ne "Domain Users"} | sort name | select name -expand Name >> $LogFile



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

# Reset password on the account

    $PasswordLength = 40 #generate a random 40 digit password and reset user account to that
    $randomString = -join(33..126|%{[char]$_}|Get-Random -C $PasswordLength)
    echo $randomString >> $LogFile
    $Password = ConvertTo-SecureString -String $randomString -AsPlainText –Force 

    Set-ADAccountPassword $id -NewPassword $Password –Reset


365AccountWork

} # End of Single Deletion

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

function 365AccountWork {

# Prepare environment
# Check to see if the required modules are installed to connect to MSonline
if ((Get-InstalledModule MSOnline | select Name -ErrorAction SilentlyContinue) -eq $null) { Install-Module "MSOnline" }

# If basic auth isn't enabled then the connection to O365 will fail.
$BasicAuthEnabled = Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\ -Name "AllowBasic" -ErrorAction SilentlyContinue | Select AllowBasic -Expand AllowBasic

if ($BasicAuthEnabled -eq 0) {
Remove-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\ -Name "AllowBasic"
New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\ -Name "AllowBasic" -Value 1 -PropertyType DWORD
}

$UserCredential = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid -Credential $UserCredential -Authentication Basic –AllowRedirection
Import-PSSession $Session -AllowClobber


Connect-MsolService -Credential $Usercredential 
# get the licenses and log them to the log file
# get the licenses assigned to this account

$id = read-host "please provide the email address of the user that you wish to work on"

# Convert the mailbox to shared and wait 60 seconds for the process to complete
write-host "Converting to shared mailbox, please wait..."
Set-Mailbox $id -Type shared

sleep -s 60


# Check and log the licenses assigned to the user
$licenses = (get-MsolUser -UserPrincipalName $id).licenses.AccountSkuId
$licenses = $licenses -replace '(.*:)',""

for ($i=0; $i -lt $licenses.count; $i++ ) {

if ( $licenses -contains "SPE_E3") { echo "Microsoft 365 E3" >> $logfile}
if ( $licenses -contains "FLOW_FREE") { echo "MICROSOFT FLOW FREE" >> $logfile }
if ( $licenses -contains "SPE_E3") { echo "MICROSOFT 365 PHONE SYSTEM" >> $logfile }
if ( $licenses -contains "EXCHANGESTANDARD") { echo "EX Plan 1" >> $logfile }

}


# Remove the licenses
$mailbox = get-mailbox $id | select IsShared -expand IsShared

if ($mailbox -eq $TRUE) {

echo "mailbox converted to shared" >> $logfile

(get-MsolUser -UserPrincipalName $id).licenses.AccountSkuId | foreach {Set-MsolUserLicense -UserPrincipalName $id -RemoveLicenses $_ }

}

else { echo "Mailbox has not been converted to shared" >> $logfile }


# Add access permissions to the mailbox
$mailboxPermissions = read-host "Who needs access to this mailbox?"
Add-MailboxPermission $id -User $mailboxPermissions -AccessRights FullAccess

echo "Mailbox permissions granted to $mailboxPermissions" >> $logfile

# Add mailbox forwarder
$ForwardingAddress = read-host "Who is the mailbox being forwarded to?"
Set-Mailbox $id -ForwardingAddress $ForwardingAddress

echo "Mail forwarder has been set to $ForwardingAddress" >> $logfile

Exit-PSSession
Remove-PSSession -ID $Session.ID ##exit remote exchange powershell    

}

function TeamsAdmin {

$session = New-CsOnlineSession -Credential $UserCredential
Import-PSSession $session -AllowClobber
Connect-MicrosoftTeams

Set-CsUser -Identity $id -EnterpriseVoiceEnabled $false -HostedVoiceMail $false -OnPremLineURI $null

}

# User Deletion Menu

function Show-Menu {
    param (
        [string]$Title = 'User Deletion Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
 
    Write-Host "1: Press '1' for Manual Entry."
    Write-Host "2: Press '2' for CSV import. This will open a window to choose the CSV file"
    Write-Host "3: Press '3' for Office 365 Work."

    Write-Host "Q: Press 'Q' to quit."

}

do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
    '1' {
    SingleDeletion
    } '2' {
    BulkDeletion
    } '3' {
    365AccountWork
    }
   }
    pause
 }
 until ($selection -eq 'q')