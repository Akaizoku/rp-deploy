function Restart-WebServer {
  <#
    .SYNOPSIS
    Restart web-server

    .DESCRIPTION
    Restart the Java web-application server

    .EXAMPLE
    Restart-WebServer -Properties $Properties

    .NOTES
    File name:      Restart-WebServer.ps1
    Author:         Florian Carrier
    Creation date:  25/11/2019
    Last modified:  25/11/2019
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
    # Set properties
    $JavaProperties = Get-JavaProperties -Properties $Properties -Type "JBoss"
  }
  Process {
    Write-Log -Type "INFO" -Object "Restart $($Properties.WebServerType)"
    if (Test-Service -Name $Properties.ServiceName) {
      Restart-Service -Name $Properties.ServiceName -Force
    } else {
      Write-Log -Type "WARN" -Object "$($Properties.ServiceName) service could not be found"
      Write-Log -Type "DEBUG" -Object "Using built-in ANT start/stop method"
      $StopServer = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.JBossXMLFile -Operation "stop-server" -Properties $JavaProperties
      Assert-JBossClientOutcome -Log $StopServer -Object "$($Properties.WebServerType)" -Verb "stop"
      $StartServer = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.JBossXMLFile -Operation "start-server" -Properties $JavaProperties
      Assert-JBossClientOutcome -Log $StartServer -Object "$($Properties.WebServerType)" -Verb "start"
    }
  }
}
