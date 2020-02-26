function Set-StagingArea {
  <#
    .SYNOPSIS
    Setup staging area

    .DESCRIPTION
    Configure staging area service description table

    .NOTES
    File name:      Set-StagingArea.ps1
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
    $Table = "SLV_STAGING_AREA_DESC"
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Configuring staging area"
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
    $StagingAreaFields = [Ordered]@{
      "SLV_STAGING_AREA_DESC_ID"        = $ID
      "HOSTNAME"                        = '''' + $Properties.Hostname + ''''
      "PERSISTNT_RES_MGR_THREAD_COUNT"  = $Properties.ResultThreadCount
      "VERSION_KEY"                     = -1
    }
    # Define & execute query
    $SQLQuery = Write-InsertOrUpdate -Table $FullyQualifiedTableName -Fields $StagingAreaFields -PrimaryKey "SLV_STAGING_AREA_DESC_ID" -Vendor $Properties.DatabaseType -Identity
    Invoke-SQLCommand @SQLArguments -Query $SQLQuery
    Write-Log -Type "CHECK" -Object "Staging area configuration complete"
  }
}
