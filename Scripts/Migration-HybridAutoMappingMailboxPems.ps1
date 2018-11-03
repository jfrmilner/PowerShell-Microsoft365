<#
Auto-mapping doesn’t work as expected in an Office 365 hybrid environment - https://support.microsoft.com/en-gb/help/3080561/auto-mapping-does-not-work-as-expected-in-an-office-365-hybrid

Hybrid auto-mapping scenario - Permissions are added after the user or mailbox is moved to the cloud

Example: Jess is moved to the cloud. After the move, she requests Full Access permissions to Geoff’s mailbox on-premises.
Description: FullAccess Permissions are added to on-premises mailbox (Geoff) by using Add-MailboxPermissions but because Jess is a Mail User in the on-premises environment Exchanges unfortunately skips auto-mapping.
Cause: The Active Directory (AD) attribute msExchDelegateListLink is not populated when Full Mailbox permissions are applied in the above scenario. This attribute provides the list of users used for auto-mapping of mailboxes in Outlook.

Testing with Exchange 2013 CU20

#>

#Giving Office 365 user (Jess) Full Mailbox Access to On-Prem User (Geoff)
Add-MailboxPermission -Identity Geoff.Neville@jfrmilner.co.uk -User Jess.Henry@jfrmilner.co.uk -AccessRights FullAccess -InheritanceType All
#Get-MailboxPermission -Identity Geoff.Neville@jfrmilner.co.uk -User Jess.Henry@jfrmilner.co.uk

#Add Geoff's mailbox to Jess's List(forward) Link attribute (msExchDelegateListLink)
Set-ADUser -Identity Geoff.Neville -Add @{msExchDelegateListLink='CN=Jess Henry,OU=Group,OU=Users,OU=Group,DC=jfrmilner,DC=local'}

#The Back Link attribute (msExchDelegateListBL) is System populated [ReadOnly] but is useful for reporting
Get-ADUser Jess.Henry -Properties msExchDelegateListBL | Select-Object -ExpandProperty msExchDelegateListBL

#Additional 
#Removal of Automapping example
#Set-ADUser 'CN=Joanne Smith,OU=Users,OU=Inactive,DC=jfrmilner,DC=local' -Remove @{msExchDelegateListLink='CN=Jess Henry,OU=Group,OU=Users,OU=Group,DC=jfrmilner,DC=local'}

