# ------------------------------------------------------------------------------
# Setup job controller configuration
# ------------------------------------------------------------------------------
function Set-JobController {
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
    # Cache SQL query
    $SQLQuery = Get-Content -Path $Properties.SQLJobControllerConfiguration -Raw
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Configure job controller"
    # Custom grid configuration
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      # Set variables
      foreach ($Configuration in $Properties.JobController.GetEnumerator()) {
        Write-Log -Type "DEBUG" -Object $Configuration.Name
        $Variables = $Configuration.Value
        # Add configuration ID and hostname parameters
        $Variables.Add("SLV_JOB_CONTROLLER_DESC_ID", $ID)
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
      $JobControllerFields = [Ordered]@{
        "SLV_JOB_CONTROLLER_DESC_ID"  = $ID
        "HOSTNAME"                    = '''' + $Properties.Hostname + ''''
        "DG_CACHE_ENABLED"            = $Properties.EnableDataGroupCache
        "DG_CACHE_EVICTION"           = $Properties.CacheTimeLimit
        "DG_CACHE_FILE_SIZE"          = $Properties.CacheDiskSpaceLimit
        "DG_CACHE_TEMP_DIR"           = '''' + $($Properties.RPCacheDirectory) + ''''
        "DG_CACHE_MAX_DG"             = $Properties.CacheNrOfDataGroups
        "DG_CACHE_MIN_CT"             = $Properties.CacheDataGroupThreshold
        "VERSION_KEY"                 = -1
      }
      # Define & execute query
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_JOB_CONTROLLER_DESC" -Fields $JobControllerFields -PrimaryKey "SLV_JOB_CONTROLLER_DESC_ID" -Identity
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
    }
    Write-Log -Type "CHECK" -Object "Job controller configuration complete"
  }
}
