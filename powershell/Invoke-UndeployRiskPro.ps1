function Invoke-UndeployRiskPro {
  <#
    .SYNOPSIS
    Undeploy RiskPro

    .DESCRIPTION
    Undeploy RiskPro

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER WebServers
    The web-servers parameter corresponds to the configuration of the application servers.

    .PARAMETER Servers
    The servers parameter corresponds to the configuration of the server grid.

    .PARAMETER Unattended
    The unattended switch specifies if the script should run in non-interactive mode.

    .INPUTS
    None. You cannot pipe objects to Invoke-UndeployRiskPro.

    .OUTPUTS
    None. Invoke-UndeployRiskPro does not return any object.

    .NOTES
    File name:      Invoke-UndeployRiskPro.ps1
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
      HelpMessage = "Properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $WebServers,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Properties"
    )]
    [ValidateNotNullOrEmpty ()]
    # [System.Collections.Specialized.OrderedDictionary]
    $Servers,
    [Parameter (
      HelpMessage = "Non-interactive mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    Write-Log -Type "INFO" -Object "Undeploying $($Properties.RPWebApplication) application"
    # Loop through the grid
    foreach ($Server in $Servers) {
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      # Undeploy application
      if (-Not $Unattended) {
        $Confirm = Confirm-Prompt -Prompt "Do you want to undeploy RiskPro from host $($Server.Hostname)?"
      }
      if ($Unattended -Or $Confirm) {
        # Controller
        $Controller = $WebServer.Hostname + ':' + $WebServer.AdminPort
        # Application server administration account credentials
        $EncryptionKey    = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($WebServer.WebServerType) administration user" -Unattended:$Unattended
        Invoke-UndeployWebApp -Properties ($Properties + $WebServer) -Controller $Controller -Hostname $Server.HostName -Credentials $AdminCredentials
      } else {
        Write-Log -Type "WARN" -Object "Undeployment on host $($Server.Hostname) skipped by user"
      }
    }
    Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application undeployment complete"
  }
}
