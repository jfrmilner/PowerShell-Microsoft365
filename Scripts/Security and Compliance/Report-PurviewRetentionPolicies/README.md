# Report-PurviewRetentionPolicies.ps1
This script is based on [How to confirm that an organization-wide retention policy is applied to a mailbox](https://learn.microsoft.com/en-us/microsoft-365/compliance/ediscovery-identify-a-hold-on-an-exchange-online-mailbox?view=o365-worldwide#how-to-confirm-that-an-organization-wide-retention-policy-is-applied-to-a-mailbox). The commands detailed have been extended to automatically perform translation of policy types and GUIDs into a human readable format for reporting. 
##### This script is for Exchange Online Mailbox Retention Policies only. This excludes Retention Labels and other services such as Teams. 

Export Retention Policy Hold Tracking information from the Mailbox Diagnostic Logs of each in scope Mailbox. 
This script will create two reports:<br /> 
1.	Historic Hold Tracking Report. This provides a history of Holds applied to each Mailbox.<br />
![HistoricHoldTrackingReport](https://github.com/jfrmilner/PowerShell-Microsoft365/assets/3640168/7fffb539-9a45-40bc-b185-05b8137079ce)
[Sample-HistoricHoldTrackingReport.csv](https://github.com/jfrmilner/PowerShell-Microsoft365/blob/master/Scripts/Security%20and%20Compliance/Report-PurviewRetentionPolicies/Sample/HistoricHoldTrackingReport.csv)

3.	Active Hold Report. This provides a truth table of active Holds on each Mailbox.
![ActiveHoldReport](https://github.com/jfrmilner/PowerShell-Microsoft365/assets/3640168/189cdbde-5c99-434c-ac0f-8b4250d1aca9)
[Sample-ActiveHoldReport.csv](https://github.com/jfrmilner/PowerShell-Microsoft365/blob/master/Scripts/Security%20and%20Compliance/Report-PurviewRetentionPolicies/Sample/ActiveHoldReport.csv)

