# ------------------------------------------------------------------------------
# Setup calculator(s) configuration
# ------------------------------------------------------------------------------
function Set-Calculator {
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
    # Custom grid configuration
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      Write-Log -Type "INFO" -Object "Configure calculators"
      # Cache SQL query
      $SQLQuery = Get-Content -Path $Properties.SQLCalculatorConfiguration -Raw
      # TODO configure calculators
      # --------------------------------------------------------------------------
      Write-Log -Type "INFO" -Object "Configure calculation units"
      # Set variables
      foreach ($Configuration in $Properties.Calculator.GetEnumerator()) {
        Write-Log -Type "DEBUG" -Object $Configuration.Name
        $Variables = $Configuration.Value
        # Add configuration ID
        $Variables.Add("SLV_CALCULATOR_DESC_ID", $ID)
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
      Write-Log -Type "CHECK" -Object "Calculators configuration complete"
    } else { # Standard configuration
      Write-Log -Type "INFO" -Object "Configure $($Properties.Hostname) calculator"
      # Define fields to update
      $StagingAreaFields = [Ordered]@{
        "SLV_CALCULATOR_DESC_ID"  = $ID
        "HOSTNAME"                = '''' + $Properties.Hostname + ''''
      }
      # Define & execute query
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_CALCULATOR_HOSTNAME" -Fields $StagingAreaFields -PrimaryKey "SLV_CALCULATOR_DESC_ID" -Identity
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
      # --------------------------------------------------------------------------
      Write-Log -Type "INFO" -Object "Configure $($Properties.Hostname) calculation units"
      # Define fields to update
      $StagingAreaFields = [Ordered]@{
        "SLV_CALCULATOR_DESC_ID"  = $ID
        "NAME"                    = '''' + $Properties.Hostname + ''''
        "CALCULATION_UNIT_COUNT"  = $Properties.CalculationUnits
        "PROCESSING_THREAD_COUNT" = $Properties.ProcessingThreadCount
        "VERSION_KEY"             = -1
      }
      # Define & execute query
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_CALCULATOR_DESC" -Fields $StagingAreaFields -PrimaryKey "SLV_CALCULATOR_DESC_ID"
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
      Write-Log -Type "CHECK" -Object "Calculator configuration complete"
    }
  }
}
