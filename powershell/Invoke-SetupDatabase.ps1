function Invoke-SetupDatabase {
  <#
    .SYNOPSIS
    Setup RiskPro database

    .DESCRIPTION
    Create and configure the database for OneSumX for Risk Management

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER Drop
    The drop switch enables the removal of the database.

    .EXAMPLE
    Invoke-SetupDatabase -Properties $Properties

    .NOTES
    File name:      Invoke-SetupDatabase.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  16/12/2019
  #>
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "System properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      HelpMessage = "Drop switch"
    )]
    [Switch]
    $Drop
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Set database properties
    $JavaProperties = Get-JavaProperties -Properties $Properties -Type "Database"
  }
  Process {
    # Check operation to perform
    if ($Drop) {
      # ------------------------------------------------------------------------
      # Drop database
      # ------------------------------------------------------------------------
      Write-Log -Type "INFO" -Object "Delete database and user"
      # Check database connection
      $Ping = Test-SQLConnection -Server $Properties.DatabaseServerInstance -Database $Properties.DatabaseName -Credentials $Properties.RPDBCredentials
      if ($Ping -eq $false) {
        Write-Log -Type "ERROR" -Object "Unable to reach database $($Properties.DatabaseName) on $($Properties.DatabaseHost)" -ExitCode 1
      }
      # Close open connections
      # TODO call scripts manually
      # $KillSessionScript = Join-Path $Properties.ResDirectory -ChildPath "sqlserver\killUserSession.sql"
      $KillSession = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Operation "killUserSession" -Properties $JavaProperties
      Assert-RiskProANTOutcome -Log $KillSession -Object "User sessions" -Verb "close" -Plural
      # Drop database
      $DropDatabase = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Operation "dropUser" -Properties $JavaProperties
      Assert-RiskProANTOutcome -Log $DropDatabase -Object "$($Properties.DatabaseName) database" -Verb "drop" -Irregular "dropped"
    } else {
      # ------------------------------------------------------------------------
      # Database setup
      # ------------------------------------------------------------------------
      if (($Propertes.DatabaseType -eq "SQLServer") -And ($Properties.CreateRiskProDatabase -eq $true) -And ($Properties.CreateRiskProUser -eq $false)) {
        # TODO check if database already exists
        # Create database without user
        Write-Log -Type "INFO" -Object "Creating $($Properties.DatabaseName) database"
        $DatabaseCreationScript = Join-Path -Path $Properties.SQLDirectory -ChildPath $Properties.MSSQLDatabaseCreationScript
        $Variables = [Ordered]@{
          "sqlserver.db"        = $Properties.DatabaseName
          "sqlserver.collation" = $Properties.DatabaseCollation
        }
        $Query = Set-Tags -String (Get-Content -Path $DatabaseCreationScript -Raw) -Tags (Resolve-Tags -Tags $Variables -Prefix '${' -Suffix '}')
        # Define SQL arguments
        $SQLArguments = Set-SQLArguments -Properties $Properties -Credentials $Properties.DBACredentials
        $SQLArguments.Database = "master"
        # Execute query
        Write-Log -Type "DEBUG" -Object $Query -Obfuscate $Properties.DBACredentials.GetNetworkCredential().Password
        Invoke-SqlCmd @SQLArguments -Query $Query
        # Abort script on first error
        if (-Not $?) {
          Write-Log -Type "ERROR" -Object "An error occurred during the database creation" -ExitCode 1
        }
      } elseif ($Properties.CreateRiskProDatabase -eq $true) {
        # Create database & user
        Write-Log -Type "INFO" -Object "Creating $($Properties.DatabaseName) database and user"
        $DatabaseCreation = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Operation "createUser" -Properties $JavaProperties
        Assert-RiskProANTOutcome -Log $DatabaseCreation -Object "$($Properties.DatabaseName) database" -Verb "create"
      } else {
        # TODO check if database already exists and provided login works
      }
      # ------------------------------------------------------------------------
      # Load database schema
      Write-Log -Type "INFO" -Object "Load database schema"
      $LoadSchema = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Operation "loadSchema" -Properties $JavaProperties
      Assert-RiskProANTOutcome -Log $LoadSchema -Object "Database schema" -Verb "load"
      # ------------------------------------------------------------------------
      if ($Properties.EnablePartitioning -eq $true) {
        if (($Properties.DatabaseType -eq "SQLServer") -And ($Properties.RiskProVersion -NotMatch '9.*')) {
          Write-Log -Type "WARN" -Object "Database partitioning is not available for SQL Server in RiskPro version $($Properties.RiskProVersion)"
        } else {
          Write-Log -Type "INFO" -Object "Enabling database partitioning"
          $SetupPartitioning = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Operation "enablePartitioning" -Properties $JavaProperties
          Assert-RiskProANTOutcome -Log $SetupPartitioning -Object "Database partinioning" -Verb "enable"
        }
      } else {
        Write-Log -Type "WARN" -Object "Skipping database partitioning configuration"
      }
      # ------------------------------------------------------------------------
      Write-Log -Type "CHECK" -Object "Database setup complete"
    }
  }
}
