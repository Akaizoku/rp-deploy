# ------------------------------------------------------------------------------
# Setup staging area configuration
# ------------------------------------------------------------------------------
function Set-StagingArea {
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
    Write-Log -Type "INFO" -Object "Configure staging area"
    # Custom grid configuration
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      # Cache SQL query
      $SQLQuery = Get-Content -Path $Properties.SQLStagingAreaConfiguration -Raw
      # Set variables
      foreach ($Configuration in $Properties.StagingArea.GetEnumerator()) {
        Write-Log -Type "DEBUG" -Object $Configuration.Name
        $Variables = $Configuration.Value
        # Add configuration ID and hostname parameters
        $Variables.Add("SLV_STAGING_AREA_DESC_ID", $ID)
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
      $StagingAreaFields = [Ordered]@{
        "SLV_STAGING_AREA_DESC_ID"        = $ID
        "HOSTNAME"                        = '''' + $Properties.Hostname + ''''
        "PERSISTNT_RES_MGR_THREAD_COUNT"  = $Properties.ResultThreadCount
        "VERSION_KEY"                     = -1
      }
      # Define & execute query
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_STAGING_AREA_DESC" -Fields $StagingAreaFields -PrimaryKey "SLV_STAGING_AREA_DESC_ID" -Identity
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
    }
    Write-Log -Type "CHECK" -Object "Staging area configuration complete"
  }
}
