break #Until this code is wrapped into a function please edit manually and use Run Selection (F8).

<#
SendAs AccessRight Permission Script for use during Exchange Online Mailbox Migration transitional phase only
This script applies a workaround of using Recipient Permissions when Mailbox Permissions are not possible, usually because the target Mailbox of the Permission entry has not been migrated.
Once both elements of the AccessRight Permission are present in the same Exchange Org (Exchange Online/On-Prem) it is recommended that the Recipient Permission be removed and Mailbox Permission are applied. 

Auth: jfrmilner
Date: 2018-08-24

Process Logic
1. Produce Mailbox_AccessRightsFilteredWithUPN.xml via on-prem Exchange Server*
2. Import Mailbox_AccessRightsFilteredWithUPN.xml
3. Check if Migrated User from Batch had existing permission(s)
4. If yes then apply to Recipient Object if not already present else skip

*
##Access Rights of Extended Rights Mailbox Permissions Export (On-Prem)
$netBIOSName = (Get-ADDomain -Current LocalComputer).NetBIOSName
$mbExtRgts = Get-Mailbox | Get-ADPermission | ? { $_.ExtendedRights -like "*Send-As*" -and $_.IsInherited -eq $false -and $_.User.toString() -ne 'NT Authority\Self' -and $_.User -match "^$netBIOSName\\" } 
#Add UPN of User
$mbExtRgts | Add-Member -MemberType ScriptProperty -Name UserPrincipalName -Value { (Get-ADUser ($this.User -replace "$netBIOSName\\")).UserPrincipalName } -Force
#Add UPN of Identity (Target)
$mbExtRgts | Add-Member -MemberType ScriptProperty -Name IdentityUserPrincipalName -Value { (Get-Mailbox -Identity $this.Identity).UserPrincipalName } -Force
#Export
$mbExtRgts | Export-Clixml C:\Support\jfrmilner\Mailbox_AccessRightsFilteredWithUPN.xml

#>

#Import on-prem permissions audit
$mbExtRgts = Import-Clixml "C:\Support\Mailbox_AccessRightsFilteredWithUPN.xml" -ErrorAction Stop
if (!($mbExtRgts)) {
    Write-Error -Message "Please generate Mailbox_AccessRightsFilteredWithUPN.xml, see comment block for details"
    break
}

#Exchange Online Connection and Authentication
if (!($userCredentialO365) {
    $userCredentialO365 = Get-Credential
}
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $userCredentialO365 -Authentication  Basic -AllowRedirection
Import-PSSession $Session

#Migration cmds
#Example 1 - Mailboxes from Batch Name
$mbBatch = Get-MoveRequest -BatchName "MigrationService:Batch 1" | Get-Recipient
#Example 2 - Individual Mailbox
#$mbBatch = Get-Recipient -Identity 'john.milner@jfrmilner.co.uk'

foreach ($mb in $mbBatch) {
    #Check on-prem audit for user
    $permsSendAsAll = $mbExtRgts | Where-Object { $_.UserPrincipalName -eq $mb.PrimarySmtpAddress }
    #Process found permissions
    if ($permsSendAsAll) {
        foreach ($permsSendAs in $permsSendAsAll) {
            $targetRecipient = Get-Recipient $permsSendAs.IdentityUserPrincipalName
            if ($targetRecipient.RecipientTypeDetails -eq "MailUser") {
                $targetRecipientCurrent = $targetRecipient | Get-RecipientPermission | Where-Object { $_.Trustee -eq $mb.PrimarySmtpAddress -and $_.AccessRights -match "SendAs"}
                if (!$targetRecipientCurrent) {
                    Add-RecipientPermission $targetRecipient.Id -AccessRights SendAs -Trustee $mb.PrimarySmtpAddress #-WhatIf
                } else {
                    Write-Host ("RecipientPermission for user " + $permsSendAs.User + " on Mailbox " + $permsSendAs.Identity + " already present") -ForegroundColor DarkYellow
                }
            } else {
                Write-Host ("RecipientTypeDetails:" + $targetRecipient.RecipientTypeDetails)
            }
        }
    } else {
        Write-Host ("No SendAs Permissions for User:" + $mb.PrimarySmtpAddress) -ForegroundColor DarkGreen
    }
}