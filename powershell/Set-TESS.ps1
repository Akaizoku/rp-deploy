function Set-TESS {
  <#
    .SYNOPSIS
    Setup TESS

    .DESCRIPTION
    Configure Task Execution Support service description table

    .NOTES
    File name:      Set-TESS.ps1
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
    $Table = "SLV_TESS_DESC"
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Configuring Task Execution Support Service (TESS)"
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
    $SQLQuery = Write-InsertOrUpdate -Table $FullyQualifiedTableName -Fields $StagingAreaFields -PrimaryKey "SLV_TESS_DESC_ID" -Vendor $Properties.DatabaseType -Identity
    Invoke-SQLCommand @SQLArguments -Query $SQLQuery
    Write-Log -Type "CHECK" -Object "TESS configuration complete"
  }
}
