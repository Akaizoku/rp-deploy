function Set-CalculationConfiguration {
  <#
    .SYNOPSIS
    Setup calculation configuration

    .DESCRIPTION
    Configure calculcation environment table

    .NOTES
    File name:      Invoke-GridSetup.ps1
    Author:         Florian CARRIER
    Creation date:  15/10/2019
    Last modified:  06/02/2020
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
      HelpMessage = "Custom grid configuration switch"
    )]
    [Switch]
    $Custom
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # SQL commands arguments
    $SQLArguments = Set-SQLArguments -Properties $Properties -Credentials $Properties.RPDBCredentials
    # Database table name
    $Table = "SLV_CONFIGURATION_DESC"
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Setup RiskPro calculation configuration"
    # --------------------------------------------------------------------------
    # Custom grid configuration
    # --------------------------------------------------------------------------
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      Write-Log -Type "ERROR" -Object "Custom grid configuration not supported yet"
      Write-Log -Type "WARN"  -Object "Defaulting to standard grid configuration"
    }
    # --------------------------------------------------------------------------
    # Standard configuration
    # --------------------------------------------------------------------------
    # Define fully qualified table name
    if ($Properties.DatabaseType -eq "Oracle") {
      $FullyQualifiedTableName = [System.String]::Concat($Properties.DatabaseName, ".", $Table)
    } elseif ($Properties.DatabaseType -eq "SQLServer") {
      $FullyQualifiedTableName = [System.String]::Concat($Properties.DatabaseName, ".dbo.", $Table)
    }
    # Define fields to update
    $ConfigurationFields = [Ordered]@{
      "SLV_CONFIGURATION_DESC_ID" = $ID
      "INITIAL_PORT"              = $Properties.RiskProInitialPort
      "VERSION_KEY"               = -1
    }
    # Define & execute query
    $SQLQuery = Write-InsertOrUpdate -Table $FullyQualifiedTableName -Fields $ConfigurationFields -PrimaryKey "SLV_CONFIGURATION_DESC_ID" -Vendor $Properties.DatabaseType
    Invoke-SQLCommand @SQLArguments -Query $SQLQuery
    Write-Log -Type "CHECK" -Object "RiskPro calculation configuration complete"
  }
}
