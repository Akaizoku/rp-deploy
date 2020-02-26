function Set-JobController {
  <#
    .SYNOPSIS
    Setup job controller configuration

    .DESCRIPTION
    Configure job controller description table

    .NOTES
    File name:      Set-JobController.ps1
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
    # Cache SQL query
    $SQLQuery = Get-Content -Path $Properties.SQLJobControllerConfiguration -Raw
    # Database table name
    $Table = "SLV_JOB_CONTROLLER_DESC"
    # Initialise configuration counter
    $ID = 1
  }
  Process {
    Write-Log -Type "INFO" -Object "Configuring job controller"
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
    $SQLQuery = Write-InsertOrUpdate -Table $FullyQualifiedTableName -Fields $JobControllerFields -PrimaryKey "SLV_JOB_CONTROLLER_DESC_ID" -Vendor $Properties.DatabaseType -Identity
    Invoke-SQLCommand @SQLArguments -Query $SQLQuery
    Write-Log -Type "CHECK" -Object "Job controller configuration complete"
  }
}
