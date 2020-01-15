function Stop-WebServer {
  <#
    .SYNOPSIS
    Stop web-server

    .DESCRIPTION
    Stop the Java web-application server

    .EXAMPLE
    Stop-WebServer -Properties $Properties

    .NOTES
    File name:      Stop-WebServer.ps1
    Author:         Florian Carrier
    Creation date:  25/11/2019
    Last modified:  15/01/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "System properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    Write-Log -Type "INFO" -Object "Stop $($Properties.WebServerType)"
    if (Test-Service -Name $Properties.ServiceName) {
      Stop-Service -Name $Properties.ServiceName -Force
    } else {
      Write-Log -Type "WARN" -Object "$($Properties.ServiceName) service could not be found"
      Write-Log -Type "DEBUG" -Object "Using built-in ANT stop method"
      $JavaProperties = Get-JavaProperties -Properties $Properties -Type "JBoss"
      $StopServer     = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.JBossXMLFile -Operation "stop-server" -Properties $JavaProperties
      Assert-JBossClientOutcome -Log $StopServer -Object "$($Properties.WebServerType)" -Verb "stop"
    }
  }
}
