function Invoke-DeployRiskPro {
  <#
    .SYNOPSIS
    Deploy RiskPro

    .DESCRIPTION
    Deploy RiskPro to all application servers

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER WebServers
    The web-servers parameter corresponds to the configuration of the application servers.

    .PARAMETER Servers
    The servers parameter corresponds to the configuration of the server grid.

    .PARAMETER Unattended
    The unattended switch specifies if the script should run in non-interactive mode.

    .INPUTS
    None. You cannot pipe objects to Invoke-DeployRiskPro.

    .OUTPUTS
    None. Invoke-DeployRiskPro does not return any object.

    .NOTES
    File name:      Invoke-DeployRiskPro.ps1
    Author:         Florian Carrier
    Creation date:  17/01/2019
    Last modified:  21/01/2020
    WARNING         Deployment fails if database connection cannot be established
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
    Write-Log -Type "INFO" -Object "Deploying $($Properties.RPWebApplication) application"
    # --------------------------------------------------------------------------
    # Loop through the grid
    foreach ($Server in $Servers) {
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      # Ask user confirmation
      if (-Not $Unattended) {
        $Confirm = Confirm-Prompt -Prompt "Do you want to deploy RiskPro on host $($Server.Hostname)?"
      }
      if ($Unattended -Or $Confirm) {
        # Controller
        $Controller = $WebServer.Hostname + ':' + $WebServer.AdminPort
        # Application server administration account credentials
        $EncryptionKey    = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($WebServer.WebServerType) administration user" -Unattended:$Unattended
        # ----------------------------------------------------------------------
        # Test database connection through RiskPro data-source
        Write-Log -Type "INFO" -Object "Checking $($Properties.DataSourceName) data-source connection on host $($Server.Hostname)"
        $DataSourceConnection = Test-DataSourceConnection -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials -DataSource $Properties.DataSourceName
        if (Test-JBossClientOutcome -Log $DataSourceConnection) {
          Write-Log -Type "CHECK" -Object "Database connection successfully established"
        } else {
          Write-Log -Type "ERROR" -Object $DataSourceConnection
          Write-Log -Type "WARN"  -Object "Unable to reach RiskPro database. Please ensure the data-source is properly defined and the database is accessible" -ExitCode 1
        }
        # ----------------------------------------------------------------------
        # Deploy application
        Invoke-DeployWebApp -Properties ($Properties + $WebServer) -Controller $Controller -Hostname $Server.HostName -Credentials $AdminCredentials
      } else {
        Write-Log -Type "WARN" -Object "Deployment on host $($Server.Hostname) skipped by user"
      }
    }
    Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application deployment complete"
  }
}
