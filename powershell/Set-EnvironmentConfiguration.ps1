# ------------------------------------------------------------------------------
# Setup environment configuration
# ------------------------------------------------------------------------------
function Set-EnvironmentConfiguration {
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
    Write-Log -Type "INFO" -Object "Setup RiskPro environment configuration"
    # Custom grid configuration
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      # Cache SQL query
      $SQLQuery = Get-Content -Path $Properties.SQLEnvironmentConfiguration -Raw
      # Set variables
      foreach ($Configuration in $Properties.RPEnvironment.GetEnumerator()) {
        Write-Log -Type "DEBUG" -Object $Configuration.Name
        $Variables = $Configuration.Value
        # Add configuration ID and name parameters
        $Variables.Add("SLV_ENVIRONMENT_DESC_ID", $ID)
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
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_ENVIRONMENT_DESC" -Fields $ConfigurationFields -PrimaryKey "SLV_ENVIRONMENT_DESC_ID" -Identity
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
    }
    Write-Log -Type "CHECK" -Object "RiskPro environment configuration complete"
  }
}
