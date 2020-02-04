# ------------------------------------------------------------------------------
# Setup OLAP cube configuration
# ------------------------------------------------------------------------------
function Set-OLAPCube {
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
    Write-Log -Type "INFO" -Object "Configure OLAP cube"
    # TODO add check if version < 9
    # Custom grid configuration
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      # TODO
    } else { # Standard configuration
      # Define fields to update
      $StagingAreaFields = [Ordered]@{
        "SLV_OLAP_DESC_ID"                = $ID
        "HOSTNAME"                        = '''' + $Properties.Hostname + ''''
        "PERSISTNT_RES_MGR_THREAD_COUNT"  = $Properties.ResultThreadCount
        "VERSION_KEY"                     = -1
      }
      # Define & execute query
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_OLAP_DESC" -Fields $StagingAreaFields -PrimaryKey "SLV_OLAP_DESC_ID" -Identity
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
    }
    Write-Log -Type "CHECK" -Object "OLAP cube configuration complete"
  }
}
