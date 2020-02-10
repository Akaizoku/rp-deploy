function Invoke-ConfigureRiskPro {
  <#
    .SYNOPSIS
    Configure RiskPro

    .DESCRIPTION
    Configure RiskPro and its underlying Java application server(s)

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER WebServers
    The web-servers parameter corresponds to the configuration of the application servers.

    .PARAMETER Servers
    The servers parameter corresponds to the configuration of the server grid.

    .PARAMETER Unattended
    The unattended switch specifies if the script should run in non-interactive mode.

    .NOTES
    File name:      Invoke-ConfigureRiskPro.ps1
    Author:         Florian Carrier
    Creation date:  06/02/2020
    Last modified:  06/02/2020
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
      HelpMessage = "Application servers properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $WebServers,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Server grid properties"
    )]
    [ValidateNotNullOrEmpty ()]
    # [System.Collections.Specialized.OrderedDictionary]
    $Servers,
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
    # --------------------------------------------------------------------------
    # Repository structure
    # --------------------------------------------------------------------------
    # Check custom paths
    $CustomPaths = Resolve-Array -Array $Properties.CustomPaths -Delimiter ","
    foreach ($CustomPath in $CustomPaths) {
      # Create directory if it does not yet exist
      if (Test-Object -Path $Properties.$CustomPath -NotFound) {
        Write-Log -Type "DEBUG" -Object "Creating path $($Properties.$CustomPath)"
        New-Item -ItemType "Directory" -Path $Properties.$CustomPath -Force | Out-Null
      }
    }
    # --------------------------------------------------------------------------
    # Security
    # --------------------------------------------------------------------------
    # Encryption key
    $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
    # RiskPro database user credentials
    $Properties.RPDBCredentials = Get-ScriptCredentials -UserName $Properties.DatabaseUsername -Password $Properties.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro database user" -Unattended:$Unattended
  }
  Process {
    Write-Log -Type "INFO" -Object "Configuration of RiskPro version $($Properties.RiskProVersion)"
    # --------------------------------------------------------------------------
    # Preliminary checks
    # --------------------------------------------------------------------------
    # Test database connection
    if (-Not $SkipDB) {
      Write-Log -Type "INFO" -Object "Checking database server connectivity"
      $DatabaseCheck = Test-DatabaseConnection -DatabaseVendor $Properties.DatabaseType -Hostname $Properties.DatabaseHost -PortNumber $Properties.DatabasePort -Instance $Properties.DatabaseInstance -Credentials $Properties.RPDBCredentials
      if (-Not $DatabaseCheck) {
        Write-Log -Type "ERROR" -Object "Unable to reach database server ($($Properties.DatabaseServerInstance))" -ExitCode 1
      }
    }
    # Check applications servers
    foreach ($Server in $Servers) {
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($Webserver.WebServerType) administration user" -Unattended:$Unattended
      # TODO manage remote servers
      Write-Log -Type "INFO" -Object "Check $($Server.Hostname) host web-server"
      $Running = Resolve-ServerState -Path $Properties.JBossClient -Controller ($WebServer.Hostname + ':' + $WebServer.AdminPort) -HTTPS:$Properties.EnableHTTPS
      if ($Running -eq $false) {
        # Start web-server
        Start-WebServer -Properties ($Properties + $WebServer)
      }
    }
    # --------------------------------------------------------------------------
    # Configure database
    # --------------------------------------------------------------------------
    # Configure grid
    if (-Not $SkipDB) {
      if ($Properties.CustomGridConfiguration -eq $true) {
        # TODO setup grid configuration from grid CSV files
        Write-Log -Type "ERROR" -Object "Custom grid configuration is not yet supported"
        Write-Log -Type "WARN"  -Object "Skipping database configuration"
      } else {
        if ($Properties.DatabaseType -eq "SQLServer") {
          foreach ($Server in $Servers) {
            # Get server properties
            $WebServer = $WebServers[$Server.Hostname]
            Invoke-GridSetup -Properties ($Properties + $WebServer) -Server $Server
          }
        } else {
          Write-Log -Type "WARN" -Object "Skipping grid configuration"
        }
      }
    } else {
      Write-Log -Type "WARN" -Object "Skipping database configuration"
    }
    # --------------------------------------------------------------------------
    # Configure Java application server(s)
    # --------------------------------------------------------------------------
    # # Loop through the grid
    # foreach ($Server in $Servers) {
    #   Write-Log -Type "INFO" -Object "Configuring $($Server.Hostname) application server"
    #   # Get server properties
    #   $WebServer = $WebServers[$Server.Hostname]
    #   # Encryption key
    #   $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
    #   # WildFly administration account
    #   $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($WebServer.WebServerType) administration user" -Unattended:$Unattended
    #   # Check web-server status
    #   Write-Log -Type "DEBUG" -Object "Check application server status"
    #   $Controller = $WebServer.Hostname + ':' + $WebServer.AdminPort
    #   $Running = Resolve-ServerState -Path $Properties.JBossClient -Controller $Controller -HTTPS:$Properties.EnableHTTPS
    #   if ($Running -eq $false) {
    #     Write-Log -Type "WARN" -Object "Application server $($Server.Hostname) is not running"
    #     if ($Attended) {
    #       $Confirm = Confirm-Prompt -Prompt "Do you want to start the application server?"
    #     }
    #     if ($Unattended -Or $Confirm) {
    #       # Start web-server
    #       Start-WebServer -Properties ($Properties + $WebServer)
    #       # Wait for server to run
    #       Wait-WildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials -TimeOut 300 -RetryInterval 1
    #     }
    #   }
    #   # Configure web-server
    #   Invoke-SetupJBoss -Properties ($Properties + $WebServer) -Server $Server -Credentials $AdminCredentials
    # }
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "Configuration successfully set for RiskPro $($Properties.RiskProVersion)"
  }
}
