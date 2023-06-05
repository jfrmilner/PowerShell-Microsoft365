function New-IndividualMigrationBatch {
    <#
    .SYNOPSIS
    Individual Mailbox Moves using Migration Batch (Seen in Exchange Admin Portal + NotificationEmails)
    .EXAMPLE
    New-IndividualMigrationBatch -mailbox "josie.taylor@jfrmilner.co.uk" -targetDeliveryDomain 'jfrmilner.mail.onmicrosoft.com' -notificationEmails "john.milner@jfrmilner.co.uk"
    .EXAMPLE
    $individualMigrationBatch = Get-Content C:\Support\IndividualMigrationBatch01.txt #Text File of string emailaddresses
    $individualMigrationBatch | Get-Recipient #Check each mailbox resolves to a recipient object
    foreach ($mailbox in $individualMigrationBatch) {
        New-IndividualMigrationBatch -mailbox $mailbox -targetDeliveryDomain 'jfrmilner.mail.onmicrosoft.com' -notificationEmails "john.milner@jfrmilner.co.uk"
    }
    .NOTES
    Auth: jfrmilner
    Version     Date        Comment
    1.0         2018-11     Initial Release.
    1.1         2023-06     Removed BadItem Limit. Batches will default to Data Consistency Score (DCS).
    #>
    param (
        [parameter(Mandatory)]
        $mailbox,
        [parameter(Mandatory)]
        $targetDeliveryDomain,
        [parameter(Mandatory)]
        $notificationEmails,
        $migrationEndpointOnPrem
    )

    begin {
	}#begin
    process {
        try {

            if ($migrationEndpointOnPrem) {
                $migrationEndpointOnPrem = Get-MigrationEndpoint -Identity $migrationEndpointOnPrem -ErrorAction Stop
            } else {
                $migrationEndpointOnPremAll = Get-MigrationEndpoint
                if ($migrationEndpointOnPremAll) {
                    $migrationEndpointOnPrem = $migrationEndpointOnPremAll | Select-Object -First 1
                    Write-Verbose -Message "No migrationEndpointOnPrem specified, using first available: $($MigrationEndpointOnprem.Identity)"
                }
            }
            # Path to temp csv file
            $CSVFile = "$env:temp\O365_temp.csv"
            # Create temp csv file
            [PSCustomObject]@{"EmailAddress" = $mailbox} | Export-Csv -Path $CSVFile -NoTypeInformation
            # Import temp csv file
            Import-Csv -Path $CSVFile
            # Create Migration Batch
            New-MigrationBatch -Name $mailbox -CSVData ([System.IO.File]::ReadAllBytes($CSVFile)) -AutoStart -SourceEndpoint $MigrationEndpointOnprem.Identity -TargetDeliveryDomain $targetDeliveryDomain -CompleteAfter ((Get-Date).AddDays(110).ToUniversalTime()) -NotificationEmails $notificationEmails
          }
          catch [system.exception] {
            Write-Host '$_ is' $_
            Write-Host '$Error[0].GetType().FullName is' $Error[0].GetType().FullName
            Write-Host '$Error[0].Exception is' $Error[0].Exception
            Write-Host '$Error[0].Exception.GetType().FullName is' $Error[0].Exception.GetType().FullName
            Write-Host '$Error[0].Exception.Message is' $Error[0].Exception.Message
          }
          finally {
          }
	}#process
    end {
	}#end
}