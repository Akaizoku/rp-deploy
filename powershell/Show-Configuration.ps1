function Show-Configuration {
  <#
    .SYNOPSIS
    Show configuration

    .DESCRIPTION
    Display the script configuration

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER DatabaseProperties
    The database properties parameter corresponds to the configuration of the database.

    .PARAMETER WebServers
    The web-servers parameter corresponds to the configuration of the servers.

    .PARAMETER Servers
    The servers parameter corresponds to the configuration of the grid.

    .NOTES
    File name:      Show-Configuration.ps1
    Author:         Florian Carrier
    Creation date:  17/01/2020
    Last modified:  17/01/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Script properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Database properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $DatabaseProperties,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Servers properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $WebServers,
    [Parameter (
      Position    = 4,
      Mandatory   = $true,
      HelpMessage = "Grid properties"
    )]
    [ValidateNotNullOrEmpty ()]
    # [System.Collections.Specialized.OrderedDictionary]
    $Servers
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Display colour
    $Colour = "Cyan"
  }
  Process {
    # Display default x custom script configuration
    Write-Log -Type "INFO" -Object "Script configuration"
    Write-Host -Object ($Properties | Out-String).Trim() -ForegroundColor $Colour
    # Display database configuration
    Write-Log -Type "INFO" -Object "Database configuration"
    Write-Host -Object ($DatabaseProperties | Out-String).Trim() -ForegroundColor $Colour
    # Display environment (servers) configuration
    foreach ($WebServer in $WebServers.GetEnumerator()) {
      Write-Log -Type "INFO" -Object "$($WebServer.Key) host configuration"
      Write-Host -Object ($WebServer.Value | Out-String).Trim() -ForegroundColor $Colour
    }
    # Display RiskPro grid configuration
    Write-Log -Type "INFO" -Object "Grid configuration"
    Write-Host -Object ($Servers | Out-String).Trim() -ForegroundColor $Colour
  }
}
