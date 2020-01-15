function Start-WebServer {
  <#
    .SYNOPSIS
    Start web-server

    .DESCRIPTION
    Start the Java web-application server

    .EXAMPLE
    Start-WebServer -Properties $Properties

    .NOTES
    File name:      Start-WebServer.ps1
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
    Write-Log -Type "INFO" -Object "Start $($Properties.WebServerType)"
    if (Test-Service -Name $Properties.ServiceName) {
      Start-Service -Name $Properties.ServiceName
    } else {
      Write-Log -Type "WARN" -Object "$($Properties.ServiceName) service could not be found"
      Write-Log -Type "DEBUG" -Object "Using built-in ANT start method"
      $JavaProperties = Get-JavaProperties -Properties $Properties -Type "JBoss"
      $StartServer    = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.JBossXMLFile -Operation "start-server" -Properties $JavaProperties
      Assert-JBossClientOutcome -Log $StartServer -Object "$($Properties.WebServerType)" -Verb "start"
    }
  }
}
