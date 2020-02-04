# ------------------------------------------------------------------------------
# Configure log properties
# ------------------------------------------------------------------------------
function Set-LogProperties {
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
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Server properties"
    )]
    [ValidateNotNullOrEmpty ()]
    # [System.Collections.Specialized.OrderedDictionary]
    $Server
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Define log file name and location
    $LogFileName = $Server.HostName + ".log"
    $LogLocation = Resolve-URI -URI $Properties.RPLogDirectory -RestrictedOnly
  }
  Process {
    # Load template log configuration file
    $LogProperties = Get-Properties -File $Properties.RPLogProperties -Directory $Properties.TemplateDirectory
    # Update log configuration
    $LogProperties.'log4j.appender.logfile.File' = $LogLocation + '/' + $LogFileName
    Write-Log -Type "DEBUG" -Object $LogProperties
    # Save log configuration
    $Log4JProperties = Join-Path -Path $Properties.RPMainConfDirectory -ChildPath ($Properties.RPLogProperties).Replace("riskpro", $Server.Hostname)
    Out-Hashtable -Hashtable $LogProperties -Path $Log4JProperties -Encoding "UTF8NoBOM"
    # Return log file path
    Write-Log -Type "DEBUG" -Object $Log4JProperties
    return $Log4JProperties
  }
}
