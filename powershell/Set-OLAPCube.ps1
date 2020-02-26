function Set-OLAPCube {
  <#
    .SYNOPSIS
    Setup OLAP cube

    .DESCRIPTION
    Configure OLAP cube service description table

    .NOTES
    File name:      Set-OLAPCube.ps1
    Author:         Florian CARRIER
    Creation date:  15/10/2019
    Last modified:  05/02/2020
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
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Configure OLAP cube"
    # Check version number
    if (Compare-Version -Version $Properties.RiskProVersion -Operator "ge" -Reference "9.0.0" -Format "semantic") {
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
        $SQLQuery = Write-InsertOrUpdate -Table "SLV_OLAP_DESC" -Fields $StagingAreaFields -PrimaryKey "SLV_OLAP_DESC_ID" -Vendor $Properties.DatabaseType -Identity
        Invoke-SQLCommand @SQLArguments -Query $SQLQuery
      }
      Write-Log -Type "CHECK" -Object "OLAP cube configuration complete"
    } else {
      # If version < 9
      Write-Log -Type "DEBUG" -Object "Table SLV_OLAP_DESC does not exists in versions lower than 9"
      Write-Log -Type "WARN" -Object "Skipping OLAP cube configuration"
    }
  }
}
