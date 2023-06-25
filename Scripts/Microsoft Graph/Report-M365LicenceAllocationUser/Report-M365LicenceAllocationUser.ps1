<#
  .SYNOPSIS
    Microsoft 365 Licence Report - User View.
    This script produces a licence report for a selection of Users. Currently
    this is configured for All Users. Please connect with Connect-MgGraph before
    running this script. The ‘Product names and service plan identifiers for
    licensing.csv’ will attempt to be download if not found in the same directory
    as the Report-M365LicenceAllocationTenant.ps1 file.

  .NOTES
    File: Report-M365LicenceAllocationUser.ps1
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

    #All Mailboxes Licence Report
    #$users = Get-Mailbox -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -ne 'DiscoveryMailbox' } | ForEach-Object { Get-MgUser -UserId $_.UserPrincipalName -Property Id, DisplayName, Mail, UserPrincipalName, UserType, AssignedLicenses }

    #All Users
    $users = Get-MgUser -All -Property Id, DisplayName, Mail, UserPrincipalName, UserType, AssignedLicenses

    $licencesAll = $users.AssignedLicenses | Select-Object -Property SkuId -Unique
    $licencesAllProduct_Display_Names = $licencesAll | ForEach-Object { $products[$_.SkuId] } | Select-Object -ExpandProperty "Product_Display_Name" | Sort-Object

    #Process each user and in turn each licence
    foreach ($user in $users) {

        foreach ($licence in $user.AssignedLicenses.SkuId) {
            #Add Product_Display_Name Note Property to user Obj. These Note Properties will be used to create the Licence truth table.
            $user | Add-Member -Name $products[$licence].Product_Display_Name -MemberType NoteProperty -Value $true
        }

    }
    ##Report output
    #Only report on licences actively assigned to users in $users
    $licenceReport = $users | Select-Object -Property ("DisplayName", @{n = "PrimarySmtpAddress"; e = { $_.mail } } + $licencesAllProduct_Display_Names )
    $licenceReport | Export-Csv -NoTypeInformation -Path Report-M365LicenceAllocationUser.csv

}
catch [system.exception] {
    Write-Host '$_ is' $_
    Write-Host '$Error[0].GetType().FullName is' $Error[0].GetType().FullName
    Write-Host '$Error[0].Exception is' $Error[0].Exception
    Write-Host '$Error[0].Exception.GetType().FullName is' $Error[0].Exception.GetType().FullName
    Write-Host '$Error[0].Exception.Message is' $Error[0].Exception.Message
}









