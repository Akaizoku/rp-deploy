function Invoke-MigrateDatabase {
  <#
    .SYNOPSIS
    Migrate RiskPro database

    .DESCRIPTION
    Upgrade the database of OneSumX for Risk Management

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .EXAMPLE
    Invoke-MigrateDatabase -Properties $Properties

    .NOTES
    File name:      Invoke-MigrateDatabase.ps1
    Author:         Florian Carrier
    Creation date:  25/11/2019
    Last modified:  09/03/2020
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
    $Properties
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Define partinioning flag
    if ($Properties.EnablePartitioning -eq $true) {
      $Partitioning = $true
    } else {
      $Partitioning = $false
    }
  }
  Process {
    Write-Log -Type "INFO" -Object "Migrating database"
    $Migration = Invoke-MigratorTool -JavaPath $Properties.JavaPath -MigratorTool $Properties.MigratorToolPath -DatabaseVendor $Properties.DatabaseDriver -DatabaseHost $Properties.DatabaseHost -DatabasePort $Properties.DatabasePort -DatabaseInstance $Properties.DatabaseInstance -Version $Properties.RiskProVersion -Credentials $Properties.RPDBCredentials -Log $Properties.MigrationLog -Partitioning:$Partitioning -Backup -Silent
    # Check outcome
    if (Test-MigratorToolOutcome -Log $Migration) {
      Write-Log -Type "CHECK" -Object "Database successfully migrated"
      return $true
    } else {
      $ErrorPatterns = @(
        [RegEx]::New('(?<=(\[ERROR\])).+'),
        [RegEx]::New('(?<=(\[SEVERE\])).+')
      )
      # Retrieve errors
      foreach ($Line in ($Migration -split "`n")) {
        foreach ($ErrorPattern in $ErrorPatterns) {
          $ErrorMessage = Select-String -InputObject $Line -Pattern $ErrorPattern | Select-Object -ExpandProperty "Matches" | Select-Object -ExpandProperty "Value"
          if ($ErrorMessage) {
            Write-Log -Type "WARN" -Object $ErrorMessage
          }
        }
      }
      Write-Log -Type "ERROR" -Object "Database migration failed"
      return $false
    }
  }
}
