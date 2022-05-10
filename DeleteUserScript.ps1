Function FindUser {
Get-ADUser -Filter { displayName -like $UserD  | select samAccountName }
}

Function ConnectO365 {
$UserCredential = Get-Credential 
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session
}

Function FindUser {
Get-ADUser -Filter { displayName -like $UserD }
}

# Get the name of the user to be deleted
$UserD = Read-Host "Provide the username of the user that you wish to delete?"

$Use365 = read-host "Does this company use Office 365?"
if ($Use365 -eq Yes) { ConnectO365 } 

