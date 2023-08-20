<#
.SYNOPSIS
Microsoft 365 Licence Report - Tenant View.
This script produces a licence report similar to what can be found at
https://admin.microsoft.com/AdminPortal/Home#/licenses. Connect to MS Graph
with Connect-MgGraph before running this script. The ‘Product names and
    service plan identifiers for licensing.csv’ will attempt to be download if not
found in the same directory as the Report-M365LicenceAllocationTenant.ps1 file.

.NOTES
File: Report-M365LicenceAllocationTenant.ps1
Author: John Milner / jfrmilner
Version: v1.0 - 2023-06-25 - Initial Release
Version: v1.1 - 2023-08-20 - Added SKU Suspended, Warning and LockedOutUnits status to report if applicable.

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

#>

# Connect-MgGraph -Scopes 'Directory.Read.All'
try {
    #csv source - https://learn.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
    if (!(Test-Path $($PSScriptRoot + '\Product names and service plan identifiers for licensing.csv'))) {
        Write-Warning -Message "Product names and service plan identifiers for licensing.csv not found. Attempting download."
        Invoke-WebRequest -Uri 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv' -OutFile $($PSScriptRoot + '\Product names and service plan identifiers for licensing.csv')
    }
    #Friendly Name $products Hash Table
    $csvData = Import-Csv -LiteralPath $($PSScriptRoot + '\Product names and service plan identifiers for licensing.csv') | Sort-Object -Property GUID -Unique
    $products = [Ordered]@{}
    $csvData | ForEach-Object { $products.Add($_.GUID, $_) }

    #Tenant View - Report M365 Licence Allocation for Tenant
    #Represents information about a service SKU that a company is subscribed to. https://learn.microsoft.com/en-us/graph/api/resources/subscribedsku?view=graph-rest-1.0
    $subscribedSku = Get-MgSubscribedSku -All
    $subscribedSkuReport = foreach ($serviceSku in $subscribedSku) {
        #Lookup sku using $products Hash Table
        $productDisplayName = $products[$serviceSku.SkuId].Product_Display_Name
        #If SKU is not found then attempt a simple pretty of the SKU Part Number ie Microsoft_Entra_Permissions_Management or Advanced_Data_Residency
        if ($null -eq $productDisplayName) { $productDisplayName = $serviceSku.SkuPartNumber -replace "_", " " }
        #Add Note Properties
        $serviceSku | Add-Member -Name "ProductDisplayName" -MemberType NoteProperty -Value $productDisplayName
        $serviceSku | Add-Member -Name "EnabledUnits" -MemberType NoteProperty -Value $serviceSku.PrepaidUnits.Enabled
        $serviceSku | Add-Member -Name "SuspendedUnits" -MemberType NoteProperty -Value $serviceSku.PrepaidUnits.Suspended
        $serviceSku | Add-Member -Name "WarningUnits" -MemberType NoteProperty -Value $serviceSku.PrepaidUnits.Warning
        $serviceSku | Add-Member -Name "LockedOutUnits" -MemberType NoteProperty -Value $serviceSku.PrepaidUnits.lockedOut
        $serviceSku | Add-Member -Name "RemainingUnits" -MemberType NoteProperty -Value ($serviceSku.PrepaidUnits.Enabled - $serviceSku.ConsumedUnits)
        #return
        $serviceSku
    }
    #Create properties ArrayList. Remove Suspended, Warning and LockedOutUnits property if not found - https://learn.microsoft.com/en-us/graph/api/resources/licenseunitsdetail?view=graph-rest-1.0
    [System.Collections.ArrayList]$properties = "ProductDisplayName", "SkuPartNumber", "EnabledUnits", "SuspendedUnits", "WarningUnits", "LockedOutUnits", "ConsumedUnits", "RemainingUnits"
    if (($subscribedSkuReport.SuspendedUnits | Measure-Object -Sum).Sum -eq 0) { $properties.Remove("SuspendedUnits") }
    if (($subscribedSkuReport.WarningUnits | Measure-Object -Sum).Sum -eq 0) { $properties.Remove("WarningUnits") }
    if (($subscribedSkuReport.LockedOutUnits | Measure-Object -Sum).Sum -eq 0) { $properties.Remove("LockedOutUnits") }
    $subscribedSkuReport | Select-Object -Property $properties | Sort-Object -Property ProductDisplayName | Export-Csv -NoTypeInformation -Path "Report-M365LicenceAllocationTenant.csv"

}
catch [system.exception] {
    Write-Host '$_ is' $_
    Write-Host '$Error[0].GetType().FullName is' $Error[0].GetType().FullName
    Write-Host '$Error[0].Exception is' $Error[0].Exception
    Write-Host '$Error[0].Exception.GetType().FullName is' $Error[0].Exception.GetType().FullName
    Write-Host '$Error[0].Exception.Message is' $Error[0].Exception.Message
}
