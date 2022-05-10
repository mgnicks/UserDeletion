# Here's my employee termination script. It does what you're requesting and has some other bits that may be helpful also. This is designed for an om-prem domain that is synched to azure AD and office 365. It is packaged into functions, so you can take what is useful for you.

# Here's what it does: (steps 1-5 are active directory)

# Disables account
# Resets the password
# Remove from any groups they are a member of
# Clear out manager and other attributes from AD account
# Move to disabled OU (for me this OU is set not to sync with azure, so the account is deleted from o365 at next sync)
# Sync with azure so that account is deleted
# Wait to ensure sync goes through before proceeding
# Convert to shared mailbox and delegate to their manager
# Remove their licenses
# Run verification tests
# Exit remote powershell and perform cleanup


$error.clear()
$userToTerminate = Read-Host "Please enter the username of the user that you would like to terminate (just username, do not include @domain.com)"
if((Get-ADUser $userToTerminate -properties manager).manager)
{
    $originalManager = (get-aduser(Get-ADUser $userToTerminate -properties manager).manager).samaccountname #we get their current manager first before we do anything else, so that it won't be removed
}
else
{
    $originalManager = Read-Host "Manager not found in active directory, please enter manager/person who the inbox should shared with as user@domain.com"
}

$termUPN = (Get-ADUser $userToTerminate).userPrincipalName

function removeFromGroups
{
    try
    {
        $ADgroups = Get-ADPrincipalGroupMembership -Identity $userToTerminate | where {$_.Name -ne "Domain Users"}
        #Write-Host "Groups: $ADgroups"

        if ($ADgroups -ne $null)
        {
            #"Removing from groups"
            Remove-ADPrincipalGroupMembership -Identity $userToTerminate -MemberOf $ADgroups  -Confirm:$false
        }
    }
    catch
    {
        Write-Host "$userToTerminate is not in AD, or script is not functioning properly"
    }
}

function setAttributes
{
    Set-ADUser $userToTerminate -Department "hide from sharepoint" -Title "hide from sharepoint" -Manager $null
}

function resetPassword
{
    $PasswordLength = 40 #generate a random 40 digit password and reset user account to that
    $randomString = -join(33..126|%{[char]$_}|Get-Random -C $PasswordLength)
    $Password = ConvertTo-SecureString -String $randomString -AsPlainText –Force
    Set-ADAccountPassword $userToTerminate -NewPassword $Password –Reset
}
function SyncAzure
{
    Import-Module adsync
    "Syncing Azure Active Directory"
    Start-ADSyncSyncCycle
}

function disableAccount
{
    Disable-ADAccount -Identity $userToTerminate
}

function moveToDisabledOU
{
    $userDistinguishedName = (Get-ADUser $userToTerminate).DistinguishedName
    Move-ADObject -Identity $userDistinguishedName -TargetPath "OU=Disabled,OU=DOMAIN,DC=DOMAIN,DC=COM"
}

function verifyAccountProperties
{   
    $userOU = ((Get-ADUser $userToTerminate).DistinguishedName -split ",",3)[1]
    "Account Organizational Unit: $userOU"

    $TermEmpADInfo = Get-ADUser -Identity $userToTerminate -Properties Manager, Title, Department, Enabled

    $ADgroups = Get-ADPrincipalGroupMembership -Identity $userToTerminate | where {$_.Name -ne "Domain Users"}
    "Groups (besides Domain Users): $ADgroup"

    $jobTitle = $TermEmpADInfo.Title
    $department = $TermEmpADInfo.Department
    $manager = $TermEmpADInfo.manager
    $accountEnabled = $TermEmpADInfo.enabled
    $365Licenses = (get-MsolUser -UserPrincipalName $termUPN).licenses.AccountSkuId
    "Job Title: $jobTitle"
    "Department: $department"
    "Manager: $manager"
    "Enabled: $accountEnabled"
    if (!$error) #check for any outright errors (the red ones)
    {
        if( ($manager -eq $null) -and ($jobTitle -eq "hide from sharepoint") -and ($department -eq "hide from sharepoint") -and ($userOU -eq "OU=Disabled") -and ($ADGroups -eq $null) -and ($accountEnabled -eq $false)  -and ($365Licenses -eq $null))
        {
            "`n `n The termination seems to have gone properly, but please validate information above in accord with termination procedure."
        }

        else
        {
            "It seems that the termination did not complete succesfully, please verify the information above and complete manually."
            if($365Licenses -ne $null)
            {
                "`n `n Office 365 licenses not removed, please verify online"
                "`n"
                "License: $365Licenses"
            }
        }
     }

     else
     {
        "An error has occured, please check powershell prompt for errors and also verify information above."
        "msg * An error has occured, please check powershell prompt for errors and also verify information listed in terminal."| cmd #show popup
     }    
     
}

function convertToSharedMailbox($manager, $mailboxToConvert) ##convert to shared mailbox and delegate permissions to manager
{
    
    ###############  CREATE A REMOTE POWERSHELL OFFICE 365 SESSION  ###################    
    "msg * You Will Now Be Prompted For Credentials twice. Please use admin office 365 credentials (may not work with 2fa)"| cmd
    $UserCredential = Get-Credential
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid -Authentication Basic -AllowRedirection -Credential $UserCredential
    Enter-PSSession $Session
    Connect-MsolService -Credential $Usercredential 
    ###############  CREATE A REMOTE POWERSHELL OFFICE 365 SESSION  ###################
    
    if(Get-MsolUser -All -ReturnDeletedUsers | where { $_.UserPrincipalName -eq "$mailboxToConvert"})
    {
        Restore-MsolUser -UserPrincipalName $mailboxToConvert 
    }
    "Waiting for mailbox to restore, the script hasn't frozen. Please be patient"
    while ( ((Get-MsolUser -All -ReturnDeletedUsers | where { $_.UserPrincipalName -eq $mailboxToConvert}) -ne $null) -and ((Get-Recipient -filter{(EmailAddresses -eq $mailboxToConvert) } -ErrorAction SilentlyContinue) -eq $null) ) #we loop until the user 1. isn't in the deleted user's  AND 2.The user has a mailbox
    {
        Start-Sleep -s 5
    }

    #Get-Recipient -filter{(Office -like "corona") }

    Set-Mailbox $userToTerminate -Type shared
    Add-MailboxPermission $userToTerminate -User $manager -AccessRights FullAccess
    Exit-PSSession
    Remove-PSSession -ID $Session.ID ##exit remote exchange powershell    
}

function delayWithProgressBar($time, $reason)
{
    For($i = 0; $i -le $time; $i++)##while it is less than the time...

    { 
        Write-Progress -Activity $reason -percentComplete (($i / $time)*100)
        Start-Sleep -s 1
    }
}

function removeLicenses
{
    (get-MsolUser -UserPrincipalName $termUPN).licenses.AccountSkuId | foreach {Set-MsolUserLicense -UserPrincipalName $termUPN -RemoveLicenses $_}
}

disableAccount
resetPassword
removeFromGroups
setAttributes
syncAzure #sync with azure so that it can set the departmenent and job title to "hide from sharepoit" which removes them from the directory
delayWithProgressBar -time 30 -reason "Waiting on azure sync"
moveToDisabledOU #we move them to disabled OU after synching so that azure can first change the attributes, because after it is moved it will no longer sync
syncAzure
delayWithProgressBar -time 30 -reason "Waiting for azure to sync again"
convertToSharedMailbox -manager $originalManager -mailboxToConvert $termUPN
removeLicenses
"`n `r Termination process completed, validating results."
verifyAccountProperties #check for errors and print results
Get-PSSession | Remove-PSSession
[GC]::Collect()