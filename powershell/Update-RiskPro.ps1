function Update-RiskPro {
  <#
    .SYNOPSIS
    Update RiskPro

    .DESCRIPTION
    Upgrade the OneSumX for Risk Management application

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .EXAMPLE
    Update-RiskPro -Properties $Properties

    .NOTES
    File name:      Update-RiskPro.ps1
    Author:         Florian Carrier
    Creation date:  25/11/2019
    Last modified:  25/11/2019
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
    $Migration = Invoke-MigratorTool -Properties $Properties -Credentials $Properties.RPDBCredentials -Partitioning:$Partitioning -Backup
    Write-Log -Type "DEBUG" -Object $Migration
    # Check outcome
    if (Test-MigratorToolCmd -Log $Migration) {
      Write-Log -Type "CHECK" -Object "Database successfully migrated"
      return $true
    } else {
      $ErrorPatterns = @(
        [RegEx]::New('(?<=(\[ERROR\]).+(com\.frsglobal\.migrator\.console\.Launcher -- )).+'),
        [RegEx]::New('(?<=(\[SEVERE\]).+(com\.frsglobal\.migrator\.console\.Launcher -- )).+')
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
