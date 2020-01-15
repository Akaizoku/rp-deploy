function Uninstall-RiskPro {
  <#
    .SYNOPSIS
    Uninstall RiskPro

    .DESCRIPTION
    Uninstall OneSumX for Risk Management application

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .EXAMPLE
    Uninstall-RiskPro -Properties $Properties

    .NOTES
    File name:      Uninstall-RiskPro.ps1
    Author:         Florian Carrier
    Creation date:  16/12/2019
    Last modified:  16/12/2019
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
      HelpMessage = "Flag to ignore database"
    )]
    [Switch]
    $SkipDB,
    [Parameter (
      HelpMessage = "Non-interactive mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # ----------------------------------------------------------------------------
    # Security
    # ----------------------------------------------------------------------------
    # Encryption key
    $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
    # Database system administrator credentials
    $DatabaseProperties.DBACredentials = Get-ScriptCredentials -UserName $DatabaseProperties.DatabaseAdminUsername -Password $DatabaseProperties.DatabaseAdminPassword -EncryptionKey $EncryptionKey -Label "database system administrator" -Unattended:$Unattended
    # RiskPro database user credentials
    $DatabaseProperties.RPDBCredentials = Get-ScriptCredentials -UserName $DatabaseProperties.DatabaseUsername -Password $DatabaseProperties.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro database user" -Unattended:$Unattended
    # Default admin user for RiskPro (force unattended flag to use value from default configuration file)
    $RiskProAdminCredentials = Get-ScriptCredentials -UserName "admin" -Password $Properties.DefaultAdminPassword -EncryptionKey $EncryptionKey -Label "RiskPro administration user" -Unattended
  }
  Process {
    Write-Log -Type "INFO" -Object "Uninstallation of RiskPro version $($Properties.RiskProVersion)"
    # --------------------------------------------------------------------------
    # Preliminary checks
    # --------------------------------------------------------------------------
    # Check that RiskPro is installed
    Write-Log -Type "INFO" -Object "Checking installation path"
    if (-Not (Test-Object -Path $Properties.RPHomeDirectory)) {
      Write-Log -Type "ERROR" -Object "Installation path not found $($Properties.RPHomeDirectory)" -ExitCode 1
    }
    # Test database connection
    if (-Not $SkipDB) {
      Write-Log -Type "INFO" -Object "Checking database server connectivity"
      $DatabaseCheck = Test-SQLConnection -Server $DatabaseProperties.DatabaseServerInstance -Database "master" -Security -Credentials $DatabaseProperties.DBACredentials
      if (-Not $DatabaseCheck) {
        Write-Log -Type "ERROR" -Object "Unable to reach database server ($($DatabaseProperties.DatabaseServerInstance))" -ExitCode 1
      }
    }
    # --------------------------------------------------------------------------
    # Undeploy web-application(s)
    # --------------------------------------------------------------------------
    # Loop through the grid
    foreach ($Server in $Servers) {
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      $WildFlyAdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "WildFly administration user" -Unattended:$Unattended
      # --------------------------------------------------------------------
      # TODO add option to use credentials for remote servers
      Write-Log -Type "INFO" -Object "Check $($Server.Hostname) host web-server"
      $Running = Resolve-ServerState -Path $Properties.JBossClient -Controller ($WebServer.Hostname + ':' + $WebServer.AdminPort) -HTTPS:$Properties.EnableHTTPS
      if ($Running -eq $false) {
        # Start web-server
        Start-WebServer -Properties ($Properties + $WebServer)
      }
      # --------------------------------------------------------------------
      # Remove web-application
      $UndeployWebApp = Invoke-DeployWebApp -Properties ($Properties + $DatabaseProperties + $WebServer) -Credentials $WildFlyAdminCredentials -Undeploy
      # --------------------------------------------------------------------
      # Remove web-server configuration
      Invoke-SetupJBoss -Properties ($Properties + $DatabaseProperties + $WebServer) -Server $Server -Credentials $WildFlyAdminCredentials -Remove
    }
    # --------------------------------------------------------------------------
    # Drop database
    # --------------------------------------------------------------------------
    if (-Not $SkipDB) {
      Invoke-SetupDatabase -Properties ($Properties + $DatabaseProperties) -Drop
    }
    # --------------------------------------------------------------------------
    # Remove files
    # --------------------------------------------------------------------------
    # Remove applications
    Write-Log -Type "INFO" -Object "Removing RiskPro files"
    Remove-Item -Path $Properties.RPHomeDirectory -Recurse -Force -Confirm:$Attended
    if (Test-Object -Path $Properties.RPHomeDirectory) {
      Write-Log -Type "ERROR" -Object "An error occured while attempting removing the files" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Clean-up
    # --------------------------------------------------------------------------
    # TODO remove custom paths
    # TODO remove tmp directory
    # Remove environment variables
    if ($Properties.EnableEnvironmentVariable) {
      Write-Log -Type "INFO" -Object "Remove $($Properties.RiskProHomeVariable) environment variable"
      if (Test-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope) {
        if ($RPHome -eq $Properties.RPHomeDirectory) {
          Remove-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
        } else {
          Write-Log -Type "WARN" -Object "$($Properties.RiskProHomeVariable) environment variable points to a different location"
          $Continue = Confirm-Prompt -Prompt "Do you want to remove it?"
          if ($Unattended -Or $Continue) {
            Remove-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
          }
        }
      }
    }
    Write-Log -Type "CHECK" -Object "RiskPro has been successfully uninstalled"
  }
}
