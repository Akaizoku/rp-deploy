function Invoke-RestoreSchema {
  <#
    .SYNOPSIS
    Restore RiskPro database

    .DESCRIPTION
    Restore the database for OneSumX for Risk Management

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .EXAMPLE
    Invoke-RestoreSchema -Properties $Properties

    .NOTES
    File name:      Invoke-RestoreSchema.ps1
    Author:         Florian Carrier
    Creation date:  16/01/2020
    Last modified:  16/01/2020
    TODO:           Check non-blocking error "The system cannot find the path specified."
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
      Position    = 2,
      Mandatory   = $false,
      HelpMessage = "Name of path of the back-up file to restore"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $BackupFile,
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
    # Check back-up file
    if ($PSBoundParameters.ContainsKey("BackupFile")) {
      # Check if parameter is a path
      if ($BackupFile -match "^.*\\") {
        $BackupPath = $BackupFile
      } else {
        # Build back-up file path
        $BackupPath = Join-Path -Path $Properties.RPBackupDirectory -ChildPath $BackupFile
      }
    } else {
      # Retrieve latest back-up file
      $BackupFile = Get-ChildItem -Path $Properties.RPBackupDirectory -Filter "*.bak" | Sort-Object -Property "LastWriteTime" -Descending | Select-Object -Last 1
      # Check that a file exists
      if ($BackupFile -eq $null) {
        Write-Log -Type "ERROR" -Object "No back-up file was found in $($Properties.RPBackupDirectory)" -ErrorCode 1
      } else {
        # Set back-up file path
        $BackupPath = Join-Path -Path $Properties.RPBackupDirectory -ChildPath $BackupFile
      }
      # Define back-up property
      $BackupProperty = ConvertTo-JavaProperty -Properties ([Ordered]@{"backupFile" = $BackupPath})
    }
  }
  Process {
    Write-Log -Type "INFO" -Object "Restoring RiskPro dabatase ($($Properties.DatabaseName))"
    # Check back-up file
    Write-Log -Type "DEBUG" -Object $BackupPath
    if (Test-Path -Path $BackupPath) {
      # Kill open sessions
      Write-Log -Type "INFO" -Object "Close open database connexions"
      $KillSession = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Operation "killUserSession" -Properties $JavaProperties
      Assert-RiskProANTOutcome -Log $KillSession -Object "User sessions" -Verb "close" -Plural
      # Restore database
      Write-Log -Type "INFO" -Object "Restoring database backup ""$BackupFile"""
      $RestoreDatabase = Restore-Schema -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Properties ($JavaProperties + " " + $BackupProperty)
      Assert-RiskProANTOutcome -Log $RestoreDatabase -Object "RiskPro database" -Verb "restore"
    } else {
      Write-Log -Type "ERROR" -Object "File not found $BackupFile" -ErrorCode 1
    }
  }
}
