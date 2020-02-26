function Invoke-UndeployWebApp {
  <#
    .SYNOPSIS
    Undeploy RiskPro

    .DESCRIPTION
    Undeploy RiskPro from an application server

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER Controller
    The controller parameter corresponds to the controller of the application server.

    .PARAMETER Hostname
    The hostname parameter corresponds to the name of the application server host.

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the application server administration account.

    .INPUTS
    None. You cannot pipe objects to Invoke-UndeployWebApp.

    .OUTPUTS
    None. Invoke-UndeployWebApp does not return any object.

    .NOTES
    File name:      Invoke-UndeployWebApp.ps1
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
    # WAR file
    $WARFile = "$($Properties.RPWebApplication).war"
  }
  Process {
    Write-Log -Type "INFO" -Object "Undeploying $($Properties.RPWebApplication) application from host $Hostname"
    # Check application server type
    switch ($Properties.WebServerType) {
      "WildFly" {
        $UndeployApplication = Invoke-UndeployApplication -Path $Properties.JBossClient -Controller $Controller -Application $WARFile -Credentials $Credentials
        # Check outcome
        if (Select-String -InputObject $UndeployApplication -Pattern "WFLYCTL0062: Composite operation failed" -SimpleMatch -Quiet) {
          # If [WFLYCTL0216: Resource not found]
          if (Select-String -InputObject $UndeployApplication -Pattern '("WFLYCTL0216:)(.|\n)*(not found")' -Quiet) {
            Write-Log -Type "WARN" -Object "$WARFile is not deployed on host $Hostname"
          } else {
            Write-Log -Type "WARN" -Object "$WARFile could not be undeployed from host $Hostname"
            Write-Log -Type "ERROR" -Object $UndeployApplication -ExitCode 1
          }
        } else {
          Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application undeployed successfully from host $Hostname"
        }
      }
      default {
        Write-Log -Type "ERROR" -Object "$($Properties.WebServerType) application server is not supported" -ExitCode 1
      }
    }
  }
}
