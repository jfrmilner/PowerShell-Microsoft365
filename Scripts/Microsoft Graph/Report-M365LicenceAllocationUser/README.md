# Report-M365LicenceAllocationUser.ps1
This script produces a licence report for a selection or all (default) Users. Please connect to the Microsoft Graph with `Connect-MgGraph` before running this script. 
The [Product names and service plan identifiers for licensing.csv](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference) will attempt to be download if it cannot be found in the same directory as the Report-M365LicenceAllocationUser.ps1 file. 
The information in the csv file will be used to translate the SKU codes into human friendly Product Display Names.

Script output example (Report-M365LicenceAllocationUser.csv)
![Report-M365LicenceAllocationUser](https://github.com/jfrmilner/PowerShell-Microsoft365/assets/3640168/83b7e6ca-7af5-4969-8914-46a4d8da96e4)
