# Report-PurviewRetentionPolicies.ps1

Export Retention Policy Hold Tracking information from the Mailbox Diagnostic Logs of each in scope Mailbox. 
This script will create two reports:<br /> 
1.	Historic Hold Tracking Report. This provides a history of Holds applied to each Mailbox.<br />
![HistoricHoldTrackingReport](https://github.com/jfrmilner/PowerShell-Microsoft365/blob/master/Scripts/Security%20and%20Compliance/Report-PurviewRetentionPolicies/Images/HistoricHoldTrackingReport.jpg)
[Sample-HistoricHoldTrackingReport.csv](https://github.com/jfrmilner/PowerShell-Microsoft365/blob/master/Scripts/Security%20and%20Compliance/Report-PurviewRetentionPolicies/Sample/HistoricHoldTrackingReport.csv)

2.	Active Hold Report. This provides a truth table of active Holds on each Mailbox.
![ActiveHoldReport](https://github.com/jfrmilner/PowerShell-Microsoft365/blob/master/Scripts/Security%20and%20Compliance/Report-PurviewRetentionPolicies/Images/ActiveHoldReport.jpg)
[Sample-ActiveHoldReport.csv](https://github.com/jfrmilner/PowerShell-Microsoft365/blob/master/Scripts/Security%20and%20Compliance/Report-PurviewRetentionPolicies/Sample/ActiveHoldReport.csv)
