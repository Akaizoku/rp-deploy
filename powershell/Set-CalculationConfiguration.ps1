# ------------------------------------------------------------------------------
# Setup calculation configuration
# ------------------------------------------------------------------------------
function Set-CalculationConfiguration {
  [CmdletBinding ()]
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
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Setup RiskPro calculation configuration"
    # Custom grid configuration
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      # Cache SQL query
      $SQLQuery = Get-Content -Path $Properties.SQLCalculationConfiguration -Raw
      # Set variables
      foreach ($Configuration in $Properties.RPConfiguration.GetEnumerator()) {
        Write-Log -Type "DEBUG" -Object $Configuration.Name
        $Variables = $Configuration.Value
        # Add configuration ID and name parameters
        $Variables.Add("SLV_CONFIGURATION_DESC_ID", $ID)
        # Resolve NULL values
        $Variables = Resolve-SQLVariable -Variables $Variables
        # Update query parameters
        $Query = Set-Tags -String $SQLQuery -Tags (Resolve-Tags -Tags $Variables -Prefix '#{' -Suffix '}')
        # Execute statement
        Write-Log -Type "DEBUG" -Object $Query
        Invoke-SqlCmd @SQLArguments -Query $Query
        # Increment configuration counter
        $ID += 1
      }
    } else { # Standard configuration
      # Define fields to update
      $ConfigurationFields = [Ordered]@{
        "SLV_CONFIGURATION_DESC_ID" = $ID
        "INITIAL_PORT"              = $Properties.RiskProInitialPort
        "VERSION_KEY"               = -1
      }
      # Define & execute query
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_CONFIGURATION_DESC" -Fields $ConfigurationFields -PrimaryKey "SLV_CONFIGURATION_DESC_ID"
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
    }
    Write-Log -Type "CHECK" -Object "RiskPro calculation configuration complete"
  }
}
