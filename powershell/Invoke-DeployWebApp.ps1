function Invoke-DeployWebApp {
  <#
    .SYNOPSIS
    Deploy application

    .DESCRIPTION
    Deploy RiskPro to a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER Controller
    The controller parameter corresponds to the controller of the application server.

    .PARAMETER Hostname
    The hostname parameter corresponds to the name of the application server host.

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the application server administration account.

    .INPUTS
    None. You cannot pipe objects to Invoke-DeployWebApp.

    .OUTPUTS
    None. Invoke-DeployWebApp does not return any object.

    .NOTES
    File name:      Invoke-DeployWebApp.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  17/01/2020
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
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Application server controller"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Controller,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Application server hostname"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Hostname,
    [Parameter (
      Position    = 4,
      Mandatory   = $true,
      HelpMessage = "User credentials"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $WARPath = Join-Path -Path $Properties.RPWebAppDirectory -ChildPath "$($Properties.RPWebApplication).war"
  }
  Process {
    Write-Log -Type "INFO" -Object "Deploying $($Properties.RPWebApplication) application on host $Hostname"
    # Check application server type
    switch ($WebServer.WebServerType) {
      "WildFly" {
        $DeployApplication = Invoke-DeployApplication -Path $Properties.JBossClient -Controller $Controller -Application $WARPath -Credentials $Credentials -Force
        # Check outcome
        # TODO expand
        if ($DeployApplication) {
          Write-Log -Type "ERROR" -Object $DeployApplication -ExitCode 1
        } else {
          Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application deployed successfully on host $Hostname"
        }
      }
      default {
        Write-Log -Type "ERROR" -Object "$($WebServer.WebServerType) application server is not supported" -ExitCode 1
      }
    }
  }
}
