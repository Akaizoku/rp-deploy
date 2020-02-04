function Invoke-BackupSchema {
  <#
    .SYNOPSIS
    Backup RiskPro database

    .DESCRIPTION
    Back-up the database for OneSumX for Risk Management

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .EXAMPLE
    Invoke-BackupSchema -Properties $Properties

    .NOTES
    File name:      Invoke-BackupSchema.ps1
    Author:         Florian Carrier
    Creation date:  16/01/2020
    Last modified:  16/01/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      HelpMessage = "Run script in unattended mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Timestamp
    $ISOTimeStamp = Get-Date -Format "dd-MM-yyyy_HHmmss"
    # Encryption key
    $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
    # Database system administrator credentials
    $Properties.DBACredentials = Get-ScriptCredentials -UserName $Properties.DatabaseAdminUsername -Password $Properties.DatabaseAdminPassword -EncryptionKey $EncryptionKey -Label "database system administrator" -Unattended:$Unattended
    # RiskPro database user credentials
    $Properties.RPDBCredentials = Get-ScriptCredentials -UserName $Properties.DatabaseUsername -Password $Properties.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro database user" -Unattended:$Unattended
    # Set database properties
    $JavaProperties = Get-JavaProperties -Properties $Properties -Type "Database"
    # Define backup properties
    $BackupFile     = $Properties.DatabaseName + '_' + $ISOTimeStamp + '.bak'
    $BackupPath     = Join-Path -Path $Properties.RPBackupDirectory -ChildPath $BackupFile
    $BackupProperty = ConvertTo-JavaProperty -Properties ([Ordered]@{"backupFile" = $BackupPath})
  }
  Process {
    # Back-up database
    Write-Log -Type "INFO" -Object "Backing-up RiskPro database ($($Properties.DatabaseName))"
    $BackupDatabase = Backup-Schema -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Properties ($JavaProperties + " " + $BackupProperty)
    # Check outcome
    Assert-RiskProANTOutcome -Log $BackupDatabase -Object "RiskPro database" -Verb "back-up" -Irregular "backed-up"
    # Check output file
    if (Test-Object -Path $BackupPath -NotFound) {
      Write-Log -Type "WARN"  -Object "File not found $BackupFile"
      Write-Log -Type "ERROR" -Object "An error occured during the back-up of the database" -ErrorCode 1
    }
  }
}
