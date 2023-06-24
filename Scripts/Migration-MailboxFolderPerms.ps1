<#
Mailbox *Folder* Permissions
Auth: jfrmilner
Date: 2018-10-15

Office 365 Migration Issue: A corrupted item was encountered: Folder ACL
Example: 10/09/2018 19:04:56 [AM6PR04MB5191] A corrupted item was encountered: Folder ACL "Inbox" or CorruptFolderACL

#>
function Test-MailboxMigrationHealth {
    <#
      .SYNOPSIS
      Performs tests against a given Mailbox to determine suitability for migration to Exchange Online (Office 365) in a Hybrid configuration.
      .EXAMPLE
      Test-MailboxMigrationHealth -mailbox "john.milner@jfrmilner.co.uk" -validSMTPAddresses "(@jfrmilner.mail.onmicrosoft.com$|@jfrmilner.co.uk$)" -Verbose
      .EXAMPLE
      #Batch test mailboxes
      $mailboxes = "john.milner@jfrmilner.co.uk", "roy.milner@jfrmilner.co.uk", "josie.taylor@jfrmilner.co.uk"
      $reportMigHealth = $mailboxes | % {Test-MailboxMigrationHealth -mailbox $_ -validSMTPAddresses "(@jfrmilner.mail.onmicrosoft.com$|@jfrmilner.co.uk$)" -Verbose}
      $reportMigHealth | fl

      Batch test mailboxes
      .NOTES
      https://github.com/jfrmilner/PowerShell-Microsoft365
    #>
        [CmdletBinding()]
        param (
            $mailbox,
            $validSMTPAddresses
        )

        begin {
        }#begin
        process {
                try {
                    #Mailbox of User
                    $mb = Get-Mailbox -Identity $mailbox
                    if ($mb) {
                        #Results (Return Obj)
                        $results = [PSCustomObject][ordered]@{
                            "mailbox" = $mb.PrimarySmtpAddress
                            "healthy" = ""
                            "disabledUsers" = ""
                            "invalidSMTPAddresses" = ""
                        }

                        #Exclude system folders
                        $exclusions = @("/Audits",
                                        "/Calendar Logging",
                                        "/Deletions",
                                        "/Purges",
                                        "/Recoverable Items",
                                        "/Sync Issues",
                                        "/Sync Issues/Conflicts",
                                        "/Sync Issues/Local Failures",
                                        "/Sync Issues/Server Failures",
                                        "/Versions"
                                        )

                        #Array of Mailbox Folders
                        $mailboxfolders = @(Get-MailboxFolderStatistics $mb | ? {!($exclusions -icontains $_.FolderPath)} | Select FolderPath)

                        #Get Folder Permissions
                        $progress = 0
                        $mailboxFolderPermissions = foreach ($mailboxfolder in $mailboxfolders) {
                            Write-Progress -Activity "Collecting Folder Permissions:" -PercentComplete ($progress/$mailboxfolders.Count*100)
                            $progress++
                            $folder = $mailboxfolder.FolderPath.Replace("/","\")
                            $folder = $folder.Replace([char]63743,"/") #Convert forward slashes used in folder names() back to forward slash
                            if ($folder -match "Top of Information Store") {
                            $folder = $folder.Replace("Top of Information Store","")
                            }
                            $identity = "$($mb.PrimarySmtpAddress):$folder"
                            Get-MailboxFolderPermission -Identity $identity
                        }

                        #Check ACL for disabled users
                        $mailboxFolderPermissionsUsers = $mailboxFolderPermissions.User.ADRecipient.DistinguishedName | Group-Object -NoElement
                        $progress = 0
                        $disabledUsers = foreach ($mailboxFolderPermissionsUser in $mailboxFolderPermissionsUsers) {
                            Write-Progress -Activity "Checking ACL for Disabled Users:" -PercentComplete ($progress/$mailboxFolderPermissionsUsers.Count*100)
                            $progress++
                            Get-User -Identity $mailboxFolderPermissionsUser.Name | ? { $_.UserAccountControl -match 'AccountDisabled'}
                        }
                        #Report disabled users
                        if ($disabledUsers) {
                            $results.disabledUsers = $disabledUsers
                            #Warning to Console
                            $disabledUsers | % { Write-Warning -Message "Disabled User $($_.UserPrincipalName.ToLower()) has ACL Entries on this Mailbox" }

                        }

                        #SMTP Address Check
                        $SmtpAddress = $mb.emailaddresses.SmtpAddress
                        $invalidSMTPAddresses = $SmtpAddress -notmatch $validSMTPAddresses
                        #Report invalid smtp addresses
                        if ($invalidSMTPAddresses) {
                            $results.invalidSMTPAddresses = $invalidSMTPAddresses
                            #Warning to console
                            $invalidSMTPAddresses | % { Write-Warning -Message "Invalid SMTP Address Found: $($_)" }
                        }

                    }

                }#try
              catch [system.exception] {
                Write-Host '$_ is' $_
                Write-Host '$Error[0].GetType().FullName is' $Error[0].GetType().FullName
                Write-Host '$Error[0].Exception is' $Error[0].Exception
                Write-Host '$Error[0].Exception.GetType().FullName is' $Error[0].Exception.GetType().FullName
                Write-Host '$Error[0].Exception.Message is' $Error[0].Exception.Message
              }
              finally {
              }#finally
        }#process
        end {
            if ($disabledUsers.count -gt 0 -or $invalidSMTPAddresses.count -gt 0) {
                Write-Verbose "$($mb.PrimarySmtpAddress) - invalidSMTPAddresses.count:$($invalidSMTPAddresses.count)"
                Write-Verbose "$($mb.PrimarySmtpAddress) - disabledUsers.count:$($disabledUsers.count)"
                #Report if Healthy
                $results.healthy = $false
                return $results
            } else {
                Write-Verbose "$($mailbox) is ready for Migration to Office 365"
                #Report if Healthy
                $results.healthy = $true
                return $results
            }
        }#end
}

function Remove-UserMailboxFolderPermission {
    <#
        .SYNOPSIS
        Performs the removal of User Mailbox Permissions. Typically used in conjunction with Test-MailboxMigrationHealth, passing the output of that command to this one for processing.
        .EXAMPLE
        Remove-UserMailboxFolderPermission -user john.milner@jfrmilner.co.uk -identity roy.milner@jfrmilner.co.uk -Verbose
        .EXAMPLE
        #Batch test mailboxes
        $mailboxes = "john.milner@jfrmilner.co.uk", "roy.milner@jfrmilner.co.uk", "josie.taylor@jfrmilner.co.uk"
        $reportMigHealth = $mailboxes | % {Test-MailboxMigrationHealth -mailbox $_ -validSMTPAddresses "(@jfrmilner.mail.onmicrosoft.com$|@jfrmilner.co.uk$)" -Verbose}

        foreach ($mb in ($reportMigHealth | ? { $_.disabledUsers.Length -gt 1 })) {
            foreach ($disabledUser in $mb.disabledUsers) {
                Remove-UserMailboxFolderPermission -user $disabledUser.UserPrincipalName -identity $mb.mailbox.Address -Verbose -WhatIf
            }
        }

        Batch removal of User Mailbox Permissions
        .NOTES
        https://github.com/jfrmilner/PowerShell-Office365

    #>
        [cmdletbinding(ConfirmImpact = 'Medium', SupportsShouldProcess)]
        param (
            $user,
            $identity,
            $logPath = "$env:TEMP\Remove-UserMailboxFolderPermission.csv"
        )

        begin {
        }#begin
        process {
                try {
                    ##Remove Folder Permission(s)
                    #User of permission to be removed
                    $user = Get-Mailbox -Identity $user
                    if ($user.count -ne 1) {
                        Write-Error -Message "Get-Mailbox of $User failed" -ErrorAction Stop
                        "break 1"
                        break
                    }
                    #Mailbox with permission to be removed
                    $identity = Get-Mailbox -Identity $identity
                    if ($identity.count -ne 1) {
                        Write-Error -Message "Get-Mailbox of $identity failed" -ErrorAction Stop
                        "break 2"
                        break
                    }

                    #Exclude system folders
                    $exclusions = @("/Audits",
                        "/Calendar Logging",
                        "/Deletions",
                        "/Purges",
                        "/Recoverable Items",
                        "/Sync Issues",
                        "/Sync Issues/Conflicts",
                        "/Sync Issues/Local Failures",
                        "/Sync Issues/Server Failures",
                        "/Versions"
                        )

                    #Array of Mailbox Folders
                    $mailboxfolders = @(Get-MailboxFolderStatistics -Identity $identity | ? {!($exclusions -icontains $_.FolderPath)} | Select FolderPath)

                    foreach ($mailboxfolder in $mailboxfolders) {
                        #Modify Folder Path String where required
                        $folder = $mailboxfolder.FolderPath.Replace("/","\")
                        $folder = $folder.Replace([char]63743,"/") #Convert forward slashs used in folder names() back to forward slash
                        if ($folder -match "Top of Information Store") {
                            $folder = $folder.Replace("Top of Information Store","")
                        }
                        $identityFolder = "$($identity.PrimarySmtpAddress):$folder"

                        #Check folder permissions and remove $user if found
                        $mbp = Get-MailboxFolderPermission -Identity $identityFolder -User $user -ErrorAction SilentlyContinue
                        if ($mbp) {
                            try {
                                if ($PSCmdlet.ShouldProcess("$identityFolder for user $user.",'Remove-MailboxFolderPermission')) {
                                    Remove-MailboxFolderPermission -Identity $identityFolder -User $User -Confirm:$false -ErrorAction Stop #-WhatIf
                                    #Create Log Entry (Can be used to undo changes)
                                    $logEntry = [PSCustomObject][ordered]@{ "DateTime" = (Get-Date).ToString("s") ; "IdentityFolder" = $identityFolder ;  "User" = $user.PrimarySmtpAddress.Address ; "AccessRights" = [String]$mbp.AccessRights }
                                    $logEntry | Export-Csv -Path $logPath -NoTypeInformation -Append
                                    Write-Verbose "Removed mailbox folder permission $($logEntry.AccessRights) on $($logEntry.IdentityFolder) for user $($logEntry.User)"
                                }
                            }
                            catch {
                                Write-Warning $_.Exception.Message
                            }
                        } else {
                            Write-Verbose "No folder permission(s) found on folder $identityFolder for user $user"
                        }
                    }

                }#try
                catch [system.exception] {
                    Write-Host '$_ is' $_
                    Write-Host '$Error[0].GetType().FullName is' $Error[0].GetType().FullName
                    Write-Host '$Error[0].Exception is' $Error[0].Exception
                    Write-Host '$Error[0].Exception.GetType().FullName is' $Error[0].Exception.GetType().FullName
                    Write-Host '$Error[0].Exception.Message is' $Error[0].Exception.Message
                }
                finally {
                    Write-Verbose "Folder Permission Removal Complete"
                    if (Test-Path -Path $logPath) {
                        Write-Verbose "Log file has been saved to: $logPath"
                    }
                }
        }#process
        end {
        }#end
}