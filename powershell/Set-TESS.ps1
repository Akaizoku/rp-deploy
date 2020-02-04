# ------------------------------------------------------------------------------
# Setup TESS configuration
# ------------------------------------------------------------------------------
function Set-TESS {
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
    Write-Log -Type "INFO" -Object "Configure TESS"
    # Custom grid configuration
    if ($PSBoundParameters.ContainsKey["Custom"]) {
      # Cache SQL query
      $SQLQuery = Get-Content -Path $Properties.SQLTESSConfiguration -Raw
      # Set variables
      foreach ($Configuration in $Properties.TESS.GetEnumerator()) {
        Write-Log -Type "DEBUG" -Object $Configuration.Name
        $Variables = $Configuration.Value
        # Add configuration ID
        $Variables.Add("SLV_TESS_DESC_ID", $ID)
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
        "SLV_TESS_DESC_ID"        = $ID
        "HOSTNAME"                = '''' + $Properties.Hostname + ''''
        "SHARED_FILESYSTEM_ROOT"  = '''' + $Properties.RPFileSystemRoot + ''''
        "FTP_PORT"                = $Properties.FTPPort
        # TODO check passive ports usage
        # "PASSIVE_PORTS"           =
        "INITIAL_PORT"            = $Properties.TESSInitialPort
        "VERSION_KEY"             = -1
      }
      # Define & execute query
      $SQLQuery = Write-InsertOrUpdate -Table "SLV_TESS_DESC" -Fields $StagingAreaFields -PrimaryKey "SLV_TESS_DESC_ID" -Identity
      Invoke-SqlCmd @SQLArguments -Query $SQLQuery
    }
    Write-Log -Type "CHECK" -Object "TESS configuration complete"
  }
}
