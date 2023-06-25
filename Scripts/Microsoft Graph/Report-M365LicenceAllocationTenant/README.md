# Report-M365LicenceAllocationTenant.ps1
This script produces a licence report similar to what can be found at https://admin.microsoft.com/AdminPortal/Home#/licenses. Please connect to Microsoft Graph with `Connect-MgGraph` before running this script. 
The [Product names and service plan identifiers for licensing.csv](https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference) will attempt to be download if it cannot be found in the same directory as the Report-M365LicenceAllocationTenant.ps1 file. 
The information in the csv file will be used to translate the SKU codes into human friendly Product Display Names.

Script output example (Report-M365LicenceAllocationTenant.csv)
![Report-M365LicenceAllocationTenant](https://github.com/jfrmilner/PowerShell-Microsoft365/assets/3640168/09455962-d9e9-4a04-b101-10725a411a87)

[Microsoft 365 Admin Portal view](https://admin.microsoft.com/AdminPortal/Home#/licenses)
![Report-M365LicenceAllocationTenantPortal](https://github.com/jfrmilner/PowerShell-Microsoft365/assets/3640168/5be089ae-4c62-4d3b-8110-ae34489128d5)
