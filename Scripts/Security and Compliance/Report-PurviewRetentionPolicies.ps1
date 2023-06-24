<#
  .SYNOPSIS
  Connect to Security & Compliance (Connect-IPPSSession) and EXO (Connect-ExchangeOnline) before running.

  Export Hold Tracking information from the Mailbox Diagnostic Logs of each in scope Mailbox.
  This script will create two reports:
    1.	Historic Hold Tracking Report. This provides a history of Holds applied to each Mailbox.
    2.	Active Hold Tracking Report. This provides a truth table of active Holds on each Mailbox.

  .NOTES
    File: Report-PurviewRetentionPolices.ps1
	Author: John Milner / jfrmilner
	Version: v1.0 - 2023-05-04 - Initial Release
    Version: v1.1 - 2023-06-24 - Made Retention Hold Truth Table headers dynamic.

    Legal: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Ref
    https://learn.microsoft.com/en-us/microsoft-365/compliance/ediscovery-identify-a-hold-on-an-exchange-online-mailbox?view=o365-worldwide
    Value	Description
    ed	    Indicates the End date, which is the date the retention policy was disabled. MinValue means the policy is still assigned to the mailbox.
    hid	    Indicates the GUID for the retention policy. This value will correlate to the GUIDs that you collected for the explicit or organization-wide retention policies assigned to the mailbox.
    ht	    Indicates the hold type. Values are 0 for LitigationHold, 1 for InPlaceHold, 2 for ComplianceTagHold, 3 for DelayReleaseHold, 4 for OrganizationRetention, 5 for CompliancePolicy, 6 for SubstrateAppPolicy, and 7 for SharepointPolicy.
    lsd	    Indicates the Last start date, which is the date the retention policy was assigned to the mailbox.
    osd	    Indicates the Original start date, which is the date that Exchange first recorded information about the retention policy.
#>

#Lookup Hashtable - Hold Type (Ref in .Notes)
$herestring = @'
Key,Value
0,LitigationHold
1,InPlaceHold
2,ComplianceTagHold
3,DelayReleaseHold
4,OrganizationRetention
5,CompliancePolicy
6,SubstrateAppPolicy
7,SharepointPolicy
'@
$holdTypeLookupHt = [Ordered]@{}
$herestring | ConvertFrom-Csv | ForEach-Object { $holdTypeLookupHt.Add($_.Key, $_.Value) }

#Lookup Hashtable - Retention Policy
$retentionPoliciesLookupHt = [Ordered]@{}
Get-RetentionCompliancePolicy | ForEach-Object { $retentionPoliciesLookupHt.Add($_.Guid.Guid -replace "-", $_.Name) }

#Mailboxes in scope
$mailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -ne 'DiscoveryMailbox' }
#End Date for Active Policies
$activeDateTime = Get-Date "01/01/0001 00:00:00"

#Create Reports
$report = foreach ($mailbox in $mailboxes) {

    try {
        #Get Mailbox Diagnostic Logs for each Mailbox
        $holdTrackingJson = Export-MailboxDiagnosticLogs -Identity $mailbox.Guid -ComponentName HoldTracking
        $holdTracking = $holdTrackingJson.MailboxLog | ConvertFrom-Json
        #Create PSCustomObject for each Hold
        foreach ($hold in $holdTracking) {
            #Remove Prefix and Suffix
            $retentionPoliy = $retentionPoliciesLookupHt[$hold.hid -replace "^mbx|:\d{1}$"]
            #Create return obj
            $obj = [PSCustomObject]@{
                Name              = $mailbox.PrimarySmtpAddress
                RetentionPoliy    = if ($null -eq $retentionPoliy) { $hold.hid } else { $retentionPoliy }
                HoldType          = $holdTypeLookupHt[[int]$hold.ht]
                OriginalStartDate = $hold.osd
                LastStartDate     = $hold.lsd
                EndDate           = if ($hold.ed -eq $activeDateTime) { "Active" } else { $hold.ed }
            }
            Remove-Variable -Name retentionPoliy

            #Add Active Hold Note Property to Mailbox Obj. These Note Properties will be used to create the Retention Hold truth table.
            If ($retentionPoliciesLookupHt.Values -contains $obj.RetentionPoliy -and $obj.EndDate -eq "Active") {
                Add-Member -InputObject $mailbox -Name $obj.RetentionPoliy -MemberType NoteProperty -Value $true -Force
            }

            #return obj
            $obj
            Remove-Variable -Name obj
        }

    }
    catch {
        #Error out to Host
        Write-Host '$_ is' $_
        Write-Host '$Error[0].GetType().FullName is' $Error[0].GetType().FullName
        Write-Host '$Error[0].Exception is' $Error[0].Exception
        Write-Host '$Error[0].Exception.GetType().FullName is' $Error[0].Exception.GetType().FullName
        Write-Host '$Error[0].Exception.Message is' $Error[0].Exception.Message
    }
}
##Report output
#Hold Tracking Report. Historic Holds viewpoint.
$report | Export-Csv -NoTypeInformation -Path HistoricHoldTrackingReport.csv
#Active Hold Truth Table Report. Mailbox viewpoint.
$mailboxPolicyProperties = $mailboxes | ForEach-Object { Get-Member -InputObject $_ -MemberType NoteProperty | Where-Object { $retentionPoliciesLookupHt.Values -contains $_.Name } } | Sort-Object -Unique
$mailboxes | Sort-Object -Property DisplayName | Select-Object -Property ("DisplayName", "PrimarySmtpAddress", "LitigationHoldEnabled", "WhenMailboxCreated" + $mailboxPolicyProperties.Name) | Export-Csv -NoTypeInformation -Path ActiveHoldTrackingReport.csv
