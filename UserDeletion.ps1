function UserDeletion {

$error.clear()

# Provide the name of the user - Can copy and paste from CAD form to avoid typing mistakes
$ticketref = Read-host "P{lease enter the ticket reference for this account deletion"

$fname = Read-Host "Please provide the users first name"
$lname = Read-Host "Please provide the users last name"

Write-host "Connecting to Active Directory to get user details, please wait..."
Import-module ActiveDirectory

# Find the username Using the first name and last name provided above
$username = Get-ADUser -Filter 'GivenName -eq $fname -and sn -eq $lname' -Properties *
$id = $username.SamAccountName
$idUPN = (Get-ADUser $username).userPrincipalName
$AddressBookValue = $username.msExchHideFromAddressLists
$UserIsDisabled = $username.enabled | fl

Write-host "Creating log file, please wait..."
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
echo "########## CW Ticket Reference ##########" >> $logfile
echo $ticketref >> $LogFile



################### Disable AD account ################################  
$title = "Disable account"
$message = "Do you want to disable the account?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Disables the account in AD."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Leaves the account as it is."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {DisableAccount}
        1 {}
    }

################### Reset password ################################    
$title = "Reset Password on the account"
$message = "Do you want to reset the password on the account?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Resets the password on the account."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Leaves the paswsord as it is."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {resetPassword}
        1 {}
    }

################### Hide from GAL ################################  
$title = "Hide the account from the address book"
$message = "Do you want to Hide the account from the address book?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Hides the account from the global address group."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Leaves the account as it is."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {HideFromGAL}
        1 {}
    }

################### Remove from groups ################################  
$title = "Remove from all groups"
$message = "Do you want to remove the account from all AD groups?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Remvoes this accout from all groups in AD."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Leaves the groups as they are."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {removeFromGroups}
        1 {}
    }

################### Convert to shared mailbox ################################  
$title = "Convert to Shared mailbox"
$message = "Do you wish to convert the mailbox to a shared mailbox?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Converts this mailbox to a shared mailbox."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Leaves the mailbox as is."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {ConnectO365
          convertToSharedMailbox}
        1 {}
    }

################### Add forwarder to mailbox ################################  
$title = "Add forwarder"
$message = "Do you wish to add a forwarder to this email account?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Adds a forwarder to this account."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does nothing to the forwarders on this account."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {AddForwarder}
        1 {}
    }


################### Enable out of office on mailbox ################################  
$title = "Enable Out of Office"
$message = "Do you wish to enable out of office on this email account?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Enables an out of office on this account."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does nothing to the out of office for this account."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {EnableOOO}
        1 {}
    }


################### Mailbox permissions ################################  
$title = "Adding mailbox permissions?"
$message = "Would you like to add mailbox permissions on this mailbox?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Adds a mailbox permission."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does not add any further mailbox permissions."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {AddMailboxPermissions}
        1 {}
    }



################### Remove O365 licenses ################################  
$title = "Check O365 licenses and unassign them"
$message = "Do you wish to check the O365 licenses and unassign them from this user?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Checks, logs the licenses and then removes them."

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Does nothing to the licenses."

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 1)

switch ($result)
    {
        0 {CheckLicensesAndRemove}
        1 {}
    }

}


function ConnectO365
{
    # Prepare environment
    # Check to see if the required modules are installed to connect to MSonline
    if ((Get-InstalledModule MSOnline | select Name -ErrorAction SilentlyContinue) -eq $null) { Install-Module "MSOnline" }

    # If basic auth isn't enabled then the connection to O365 will fail.
    $BasicAuthEnabled = Get-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\ -Name "AllowBasic" -ErrorAction SilentlyContinue | Select AllowBasic -Expand AllowBasic

    if ($BasicAuthEnabled -eq 0) {
        Remove-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\ -Name "AllowBasic"
        New-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Client\ -Name "AllowBasic" -Value 1 -PropertyType DWORD
       }
    
    if (!(Get-PSSession | Where { $_.ConfigurationName -eq "Microsoft.Exchange" })) { 
        $UserCredential = Get-Credential
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid -Credential $UserCredential -Authentication Basic –AllowRedirection
    Import-PSSession $Session -AllowClobber
}


}

function CheckLicensesAndRemove
{

echo "" >> $logfile
echo "########## Office 365 Licenses Assigned ##########" >> $logfile

# Check to see if the required modules are installed to connect to MSonline
if ((Get-InstalledModule MSOnline | select Name -ErrorAction SilentlyContinue) -eq $null) { Install-Module "MSOnline" }

Connect-MsolService -Credential $Usercredential

# Check and log the licenses assigned to the user
$licenses = (get-MsolUser -UserPrincipalName $idUPN).licenses.AccountSkuId
$licenses = $licenses -replace '(.*:)',""

for ($i=0; $i -lt $licenses.count; $i++ )
 
 {


 if ( $licenses -contains "SPE_E3") { echo "Microsoft 365 E3 was assigned" >> $logfile}
 if ( $licenses -contains "FLOW_FREE") { echo "MICROSOFT FLOW FREE was assigned" >> $logfile }
 if ( $licenses -contains "ADV_COMMS") { echo "Advanced Communications was assigned" >> $logfile }
 if ( $licenses -contains "CDSAICAPACITY") { echo "AI Builder Capacity add-on was assigned" >> $logfile }
 if ( $licenses -contains "SPZA_IW") { echo "APP CONNECT IW was assigned" >> $logfile }
 if ( $licenses -contains "MCOMEETADV") { echo "Microsoft 365 Audio Conferencing1 was assigned" >> $logfile }
 if ( $licenses -contains "AAD_BASIC") { echo "AZURE ACTIVE DIRECTORY BASIC was assigned" >> $logfile }
 if ( $licenses -contains "AAD_PREMIUM") { echo "AZURE ACTIVE DIRECTORY PREMIUM P1 was assigned" >> $logfile }
 if ( $licenses -contains "AAD_PREMIUM_P2") { echo "AZURE ACTIVE DIRECTORY PREMIUM P2 was assigned" >> $logfile }
 if ( $licenses -contains "RIGHTSMANAGEMENT") { echo "AZURE INFORMATION PROTECTION PLAN 1 was assigned" >> $logfile }
 if ( $licenses -contains "SMB_APPS") { echo "Business Apps (free) was assigned" >> $logfile }
 if ( $licenses -contains "MCOCAP") { echo "COMMON AREA PHONE was assigned" >> $logfile }
 if ( $licenses -contains "MCOCAP_GOV") { echo "Common Area Phone for GCC was assigned" >> $logfile }
 if ( $licenses -contains "CDS_DB_CAPACITY") { echo "Common Data Service Database Capacity was assigned" >> $logfile }
 if ( $licenses -contains "CDS_DB_CAPACITY_GOV") { echo "Common Data Service Database Capacity for Government was assigned" >> $logfile }
 if ( $licenses -contains "EMS") { echo "ENTERPRISE MOBILITY + SECURITY E3 was assigned" >> $logfile }
 if ( $licenses -contains "EMSPREMIUM") { echo "ENTERPRISE MOBILITY + SECURITY E5 was assigned" >> $logfile }
 if ( $licenses -contains "EMSPREMIUM") { echo "EX Plan 1 was assigned" >> $logfile }
 if ( $licenses -contains "EXCHANGEENTERPRISE") { echo "EXCHANGE ONLINE (PLAN 2) was assigned" >> $logfile }
 if ( $licenses -contains "EXCHANGEARCHIVE_ADDON") { echo "EXCHANGE ONLINE ARCHIVING FOR EXCHANGE ONLINE was assigned" >> $logfile }
 if ( $licenses -contains "EXCHANGESTANDARD") { echo "Exchange Online (Plan 1) was assigned" >> $logfile }
 if ( $licenses -contains "INTUNE_A") { echo "INTUNE was assigned" >> $logfile }

 }

 # Exit-PSSession
 # Remove-PSSession -ID $Session.ID ##exit remote exchange powershell
 
 (get-MsolUser -UserPrincipalName $idUPN).licenses.AccountSkuId | foreach {Set-MsolUserLicense -UserPrincipalName $idUPN -RemoveLicenses $_ }

 echo "Office 365 licenses now removed" >> $logfile

}

function CreateLogfile
{

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
$LogFile = ("$PathFound" + $username.displayname + "$ticketRef" + ".$date.log")

}

function DisableAccount
{

echo "" >> $logfile
echo "########## Disabling AD Account ##########" >> $logfile

write-host "Disabling the user account..."

# Checking if user account is disabled and adding it to the log file

echo "Checking if account is disabled... >> $LogFile"
if ($Username.Enabled -eq "TRUE") {
echo "$id is Enabled" >> $LogFile
Disable-ADAccount $id |where {$username.enabled -eq $TRUE}
echo "$id has now been disabled" >> $LogFile
 } else {
echo "$id is already disabled" >> $LogFile
    }
}

function resetPassword
{

echo "" >> $logfile
echo "########## Password Reset ##########" >> $logfile

    $PasswordLength = 15 #generate a random 40 digit password and reset user account to that
    $randomString = -join(33..126|%{[char]$_}|Get-Random -C $PasswordLength)
    echo $randomString >> $LogFile
    $Password = ConvertTo-SecureString -String $randomString -AsPlainText –Force
    Set-ADAccountPassword $id -NewPassword $Password –Reset
}

function HideFromGAL
{
# Hide the user from the address list
Set-ADUser $id -Add @{msExchHideFromAddressLists="TRUE"}
}


function removeFromGroups
{

echo "" >> $logfile
echo "########## Current AD group membership List ##########" >> $logfile
        
        $ADgroups = Get-ADPrincipalGroupMembership -Identity $id | where {$_.Name -ne "Domain Users"} | sort name | select name -expand Name >> $LogFile

        Get-ADPrincipalGroupMembership -Identity $id | 
        ? {$_.Name -ne "Domain Users"} |
        % {Remove-ADPrincipalGroupMembership -Confirm:$false -Identity $id -MemberOf $_}

}

function convertToSharedMailbox($mailboxToConvert) ##convert to shared mailbox
{

echo "" >> $logfile
echo "########## Mailbox Conversion ##########" >> $logfile

$mailboxToConvert = (get-mailbox $idUPN).userprincipalName

# Convert the mailbox to shared and wait 60 seconds for the process to complete
write-host "Converting to shared mailbox, please wait..."
Set-Mailbox $mailboxToConvert -Type shared

sleep -s 30

echo "Mailbox has been converted" >> $logfile

}


function EnableOOO ##convert to shared mailbox
{

echo "" >> $logfile
echo "########## Out Of Office ##########" >> $logfile


$mailbox = (get-mailbox $idUPN).userprincipalName

$YesToSeeOOO = read-host "Would you like to see the current Out of Office if one is set (y) or (n)?"

if ($YesToSeeOOO -eq "y") {

get-MailboxAutoReplyConfiguration -Identity $mailbox

}

$IntMessage = read-host "Please provide the message for the internal out of office message"
$ExtMessage = read-host "Please provide the message for the external out of office message"
$StartDate = read-host "Please provide the start date for the Out Of Office (format MM/DD/YYYY)"
$EndDate = read-host "Please provide the end date for the Out Of Office (format MM/DD/YYYY)"

echo "The following internal message has been set - $IntMessage" >> $logfile
echo "The following external message has been set - $ExtMessage" >> $logfile
echo "The Out of Office will start on $StartDate" >> $logfile
echo "The Out of office will end on $EndDate" >> $logfile

set-MailboxAutoReplyConfiguration -Identity $mailbox -AutoReplyState Enabled -InternalMessage $IntMessage -ExternalMessage $ExtMessage

}


function AddForwarder($mailboxToConvert) # Add forwarder on to mailbox

{

ConnectO365

echo "" >> $logfile
echo "########## Mailbox Forwarder ##########" >> $logfile
    
$mailboxToConvert = (get-mailbox "$fname $lname").userprincipalName

# Convert the mailbox to shared and wait 60 seconds for the process to complete
write-host "Checking to see if a forwarder is already set..."
$IsForwarderSet = (get-mailbox $IdUPN).ForwardingAddress

if ($IsForwarderSet -eq $null) {
# Add mailbox forwarder
$ForwardingAddress = read-host "Mailbox not currently being forwarded. Who do you want to forward this email address to (enter their email address)?"

Set-Mailbox $idUPN -ForwardingAddress $ForwardingAddress
echo "Mail forwarder has been set to $ForwardingAddress" >> $logfile
} else {

write-host "mailbox is already being forwarded to $IsForwarderSet"
echo "mailbox is already being forwarded to $IsForwarderSet" >> $logfile

$ChangeForwardingAddr = read-host "Do you wish to change the forwarding address?"

if ($ChangeForwardingAddr -eq "y" -or "Y"-or "Yes" -or "yes" -or "YES") {

$newForwarder = read-host "Please provide the email address that you want to forward to?"

Set-Mailbox $idUPN -ForwardingAddress $newForwarder
echo "mailbox forwarder has been updated to forwarded to $newForwarder" >> $logfile

        }
    }
}


function AddMailboxPermissions($mailboxToConvert) # Add forwarder on to mailbox
{

echo "" >> $logfile
echo "########## Mailbox Permissions ##########" >> $logfile

$manager = read-host "Please provide the email address of the user who needs full mailbox access?"    
$mailboxToConvert = (get-mailbox "$fname $lname").userprincipalName

Add-MailboxPermission $mailboxToConvert -User $manager -AccessRights FullAccess

echo "Mailbox permissions granted to $manager" >> $logfile

 }

function JustOutOfOffice
{
ConnectO365

$mailbox = read-host "Please enter the email address of the user."
$YesToSeeOOO = read-host "Would you like to see the current Out of Office if one is set (y) or (n)?"

if ($YesToSeeOOO -eq "y") { get-MailboxAutoReplyConfiguration -Identity $mailbox }

$SetOOO = read-host "Do you wish to set an out of office? (y) or (n)"

If ($SetOOO -eq "y") {

$IntMessage = read-host "Please provide the message for the internal out of office message"
$ExtMessage = read-host "Please provide the message for the external out of office message"
$StartDate = read-host "Please provide the start date for the Out Of Office (format MM/DD/YYYY)"
$EndDate = read-host "Please provide the end date for the Out Of Office (format MM/DD/YYYY)"

echo "The following internal message has been set - $IntMessage" >> $logfile
echo "The following external message has been set - $ExtMessage" >> $logfile
echo "The Out of Office will start on $StartDate" >> $logfile
echo "The Out of office will end on $EndDate" >> $logfile

set-MailboxAutoReplyConfiguration -Identity $mailbox -AutoReplyState Enabled -InternalMessage $IntMessage -ExternalMessage $ExtMessage

}

}



 ############### main menu function ########################################

function Show-Menu {
    param (
        [string]$Title = 'User Deletion Menu'
    )
    Clear-Host
    Write-Host "================ $Title ================"
    
    Write-Host "1: Press '1' to disable an account."
    Write-Host "2: Out of Office (Office 365)"
    Write-Host "Q: Press 'Q' to quit."

}

################### main start menu ##################################### 

do
 {
    Show-Menu
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {

    '1' { UserDeletion }
    '2' { JustOutOfOffice }
 #  '3' { functionToCall }
 #  '4' { functionToCall }
 #  '5' { functionToCall }

   }
    pause
 }
 until ($selection -eq 'q')
