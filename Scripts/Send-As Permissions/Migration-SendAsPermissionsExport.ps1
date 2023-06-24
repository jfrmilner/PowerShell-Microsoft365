<#
Produce Mailbox_AccessRightsFilteredWithUPN.xml via on-prem Exchange Server

#>

##Access Rights of Extended Rights Mailbox Permissions Export (On-Prem)
$netBIOSName = (Get-ADDomain -Current LocalComputer).NetBIOSName
$mbExtRgts = Get-Mailbox | Get-ADPermission | Where-Object { $_.ExtendedRights -like "*Send-As*" -and $_.IsInherited -eq $false -and $_.User.toString() -ne 'NT Authority\Self' -and $_.User -match "^$netBIOSName\\" }
#Add UPN of User
$mbExtRgts | Add-Member -MemberType ScriptProperty -Name UserPrincipalName -Value { (Get-ADUser ($this.User -replace "$netBIOSName\\")).UserPrincipalName } -Force
#Add UPN of Identity (Target)
$mbExtRgts | Add-Member -MemberType ScriptProperty -Name IdentityUserPrincipalName -Value { (Get-Mailbox -Identity $this.Identity).UserPrincipalName } -Force
#Export
$mbExtRgts | Export-Clixml C:\Support\jfrmilner\Mailbox_AccessRightsFilteredWithUPN.xml

