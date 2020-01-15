function Invoke-DeployWebApp {
  <#
    .SYNOPSIS
    Deploy application

    .DESCRIPTION
    Deploy (or un-deploy) an application to a WildFly instance

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the WildFly instance administration account.

    .PARAMETER Force
    The force switch defines what happens if an application is already deployed.

    .PARAMETER Undeploy
    The undeploy switch defines if the application should be undeployed.

    .INPUTS
    None. You cannot pipe objects to Invoke-DeployWebApp.

    .OUTPUTS
    None. Invoke-DeployWebApp does not return any object.

    .NOTES
    File name:      Invoke-DeployWebApp.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  15/01/2020
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
      HelpMessage = "User credentials"
    )]
    [ValidateNotNUllOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      HelpMessage = "Force switch to overwrite existing deployment"
    )]
    [Switch]
    $Force,
    [Parameter (
      HelpMessage = "Undeploy switch"
    )]
    [Switch]
    $Undeploy
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Controller
    $Controller = $Properties.Hostname + ':' + $Properties.AdminPort
    # WAR file
    $WARFile = "$($Properties.RPWebApplication).war"
    $WARPath = Join-Path -Path $Properties.RPWebAppDirectory -ChildPath $WARFile
  }
  Process {
    if ($Undeploy) {
      # Undeploy application
      Write-Log -Type "INFO" -Object "Undeploying $($Properties.RPWebApplication) application on host $($Properties.Hostname)"
      if ($PSBoundParameters.ContainsKey("Credentials")) {
        $UndeployApplication = Invoke-UndeployApplication -Path $Properties.JBossClient -Controller $Controller -Application $WARFile -Credentials $Credentials
      } else {
        $UndeployApplication = Invoke-UndeployApplication -Path $Properties.JBossClient -Controller $Controller -Application $WARFile
      }
      # Check outcome
      if (Select-String -InputObject $UndeployApplication -Pattern "Undeploy failed" -SimpleMatch -Quiet) {
        # If [WFLYCTL0216: Resource not found]
        if (Select-String -InputObject $UndeployApplication -Pattern '("WFLYCTL0216:)(.|\n)*(not found")' -Quiet) {
          Write-Log -Type "WARN" -Object "$WARFile is not deployed on host $($Properties.Hostname)"
        } else {
          Write-Log -Type "WARN" -Object "$WARFile could not be undeployed on host $($Properties.Hostname)"
          Write-Log -Type "ERROR" -Object $UndeployApplication -ExitCode 1
        }
      } else {
        Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application undeployed successfully on host $($Properties.Hostname)"
      }
    } else {
      # Deploy application
      Write-Log -Type "INFO" -Object "Deploying $($Properties.RPWebApplication) application on host $($Properties.Hostname)"
      if ($PSBoundParameters.ContainsKey("Credentials")) {
        $DeployApplication = Invoke-DeployApplication -Path $Properties.JBossClient -Controller $Controller -Application $WARPath -Force:$Force -Credentials $Credentials
      } else {
        $DeployApplication = Invoke-DeployApplication -Path $Properties.JBossClient -Controller $Controller -Application $WARPath -Force:$Force
      }
      # Check outcome
      # TODO expand
      if ($DeployApplication) {
        Write-Log -Type "ERROR" -Object $DeployApplication
      } else {
        Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application deployed successfully on host $($Properties.Hostname)"
      }
    }
  }
}
