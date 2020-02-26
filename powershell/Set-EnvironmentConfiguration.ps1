function Set-EnvironmentConfiguration {
  <#
    .SYNOPSIS
    Setup environment configuration

    .DESCRIPTION
    Configure environment description table

    .NOTES
    File name:      Set-EnvironmentConfiguration.ps1
    Author:         Florian CARRIER
    Creation date:  15/10/2019
    Last modified:  26/02/2020
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
    $Table = "SLV_ENVIRONMENT_DESC"
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Setup RiskPro environment configuration"
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
      "SLV_ENVIRONMENT_DESC_ID" = $ID
      "VERSION_KEY"             = -1
    }
    # Activate production mode if required
    if ($Properties.ProductionEnvironment -eq $true) {
      $ConfigurationFields.Add("IS_PROD", 1)
    }
    # Activate audit if required
    if ($Properties.EnableTechnicalAudit -eq $true) {
      $ConfigurationFields.Add("IS_AUDIT_ACTIVATED", 1)
    }
    # Define & execute query
    $SQLQuery = Write-InsertOrUpdate -Table $FullyQualifiedTableName -Fields $ConfigurationFields -PrimaryKey "SLV_ENVIRONMENT_DESC_ID" -Vendor $Properties.DatabaseType -Identity
    Invoke-SQLCommand @SQLArguments -Query $SQLQuery
    Write-Log -Type "CHECK" -Object "RiskPro environment configuration complete"
  }
}
