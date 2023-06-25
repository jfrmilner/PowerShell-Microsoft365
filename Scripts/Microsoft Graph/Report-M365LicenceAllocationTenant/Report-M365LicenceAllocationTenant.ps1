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
    $csvData = Import-Csv -LiteralPath $($PSScriptRoot + '\Product names and service plan identifiers for licensing.csv') | Select-Object -Property GUID, Product_Display_Name, String_Id -Unique
    $products = [Ordered]@{}
    $csvData | ForEach-Object { $products.Add($_.GUID, $_) }

    #Tenant View - Remaining All Licences
    $licencesAll = Get-MgSubscribedSku -All

    #Basic
    $licencesAll | Select-Object -Property @{n = "Product_Display_Name"; e = { $products[$_.SkuId].Product_Display_Name } }, SkuPartNumber, @{n = "AvailableUnits"; e = { ($_.PrepaidUnits.Enabled + $_.PrepaidUnits.Warning) } }, ConsumedUnits, @{n = "RemainingUnits"; e = { ($_.PrepaidUnits.Enabled + $_.PrepaidUnits.Warning) - $_.ConsumedUnits } }
    | Sort-Object -Property Product_Display_Name | Export-Csv -NoTypeInformation -Path Report-M365LicenceAllocationTenant.csv

    #Extended with Warning and Suspended Status
    #PrepaidUnits Enabled/Warning/Suspended - https://learn.microsoft.com/en-us/graph/api/resources/licenseunitsdetail?view=graph-rest-1.0
    # $licencesAll | Select-Object -Property @{n="Product_Display_Name";e={ $products[$_.SkuId].Product_Display_Name }}, SkuPartNumber, @{n="AvailableUnitsEnabled";e={$_.PrepaidUnits.Enabled}}, @{n="AvailableUnitsSuspended";e={$_.PrepaidUnits.Suspended}}, @{n="AvailableUnitsWarning";e={$_.PrepaidUnits.Warning}}, ConsumedUnits, @{n="RemainingUnits";e={$_.PrepaidUnits.Enabled - $_.ConsumedUnits}}
    # | Sort-Object -Property Product_Display_Name | Export-Csv -NoTypeInformation -Path ActiveHoldReport.csv
}
catch [system.exception] {
    Write-Host '$_ is' $_
    Write-Host '$Error[0].GetType().FullName is' $Error[0].GetType().FullName
    Write-Host '$Error[0].Exception is' $Error[0].Exception
    Write-Host '$Error[0].Exception.GetType().FullName is' $Error[0].Exception.GetType().FullName
    Write-Host '$Error[0].Exception.Message is' $Error[0].Exception.Message
}









