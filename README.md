# PowerShell - Microsoft 365

### Security and Compliance
|**Name**|**Service**|**Category**|**Description**|
|---|---|---|---|
|[Report-PurviewRetentionPolicies](https://github.com/jfrmilner/PowerShell-Microsoft365/tree/master/Scripts/Security%20and%20Compliance/Report-PurviewRetentionPolicies)|Purview|DLM|Export Retention Policy Hold Tracking information from the Mailbox Diagnostic Logs of each in scope Mailbox. This script will create two reports:<br /> 1.	Historic Hold Tracking Report. This provides a history of Holds applied to each Mailbox.<br /> 2.	Active Hold Report. This provides a truth table of active Holds on each Mailbox.|

### Microsoft Graph
|**Name**|**Service**|**Category**|**Description**|
|---|---|---|---|
[Report-M365LicenceAllocationTenant.ps1](https://github.com/jfrmilner/PowerShell-Microsoft365/tree/master/Scripts/Microsoft%20Graph/Report-M365LicenceAllocationTenant#report-m365licenceallocationtenantps1)|Graph|Graph|Create Tenant level licence report|

### Exchange Migrations, Transitions and Coexistence (Hybrid)
|**Name**|**Service**|**Category**|**Description**|
|---|---|---|---|
|[<b>Migration-SendAsPerms</b>](https://github.com/jfrmilner/PowerShell-Microsoft365/tree/master/Scripts/Send-As%20Permissions)|EXO|Migration|These scripts help apply a workaround of using Recipient Permissions when Mailbox Permissions are not possible, usually because the target Mailbox of the Permission entry has not been migrated.|
|[<b>HybridAutoMappingMailboxPems.ps1</b>](https://github.com/jfrmilner/PowerShell-Office365/blob/master/Scripts/Migration-HybridAutoMappingMailboxPems.ps1)|EX/AD|Hybrid|This script provides an example of how to grant an O365 User FullAccess Mailbox permissions to an On-Prem Mailbox with Auto-Mapping using msExchDelegateListLink.
|[<b>Migration-IndividualMailboxBatch.ps1</b>](https://github.com/jfrmilner/PowerShell-Office365/blob/master/Scripts/Migration-IndividualMailboxBatch.ps1)|EXO|Migration|This script provides a function New-IndividualMigrationBatch to create onboarding migration batches for single mailboxes. As Batch jobs can be seen on the Migration tab of the Exchange Admin Portal it allows completion tasks to be handled by portal only Admins.
|[<b>Migration-MailboxFolderPerms.ps1</b>](https://github.com/jfrmilner/PowerShell-Office365/blob/master/Scripts/Migration-MailboxFolderPerms.ps1)|EX|Migration|This script consists of two functions. <br /> 1. Test-MailboxMigrationHealth which performs tests against a given Mailbox to determine suitability for migration to Exchange Online (Office 365).<br /> 2. Remove-UserMailboxFolderPermission performs the removal of User Mailbox Permissions. Typically used in conjunction with Test-MailboxMigrationHealth, passing the output of Disabled Users from that command for removal processing. These scripts help mitigate against Errors such as "A corrupted item was encountered: Folder ACL "Inbox" or CorruptFolderACL" and "MigrationPermanentException: You can't use the domain because it's not an accepted domain for your organization." 
