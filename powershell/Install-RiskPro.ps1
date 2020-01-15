function Install-RiskPro {
  <#
    .SYNOPSIS
    Install RiskPro

    .DESCRIPTION
    Install OneSumX for Risk Management application

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .EXAMPLE
    Install-RiskPro -Properties $Properties

    .NOTES
    File name:      Install-RiskPro.ps1
    Author:         Florian Carrier
    Creation date:  16/12/2019
    Last modified:  20/12/2019
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
    Write-Log -Type "INFO" -Object "Installation of RiskPro version $($Properties.RiskProVersion)"
    # --------------------------------------------------------------------------
    # Preliminary checks
    # --------------------------------------------------------------------------
    # Check that RiskPro is not already installed
    Write-Log -Type "INFO" -Object "Checking installation path"
    if (Test-Object -Path $Properties.RPHomeDirectory) {
      Write-Log -Type "ERROR" -Object "Path already exists $($Properties.RPHomeDirectory)" -ExitCode 1
    }
    # Check RP_HOME environment variable
    if (Test-EnvironmentVariable -Name $Properties.RiskProHomeVariable) {
      $RiskProHome = Get-EnvironmentVariable -Name $Properties.RiskProHomeVariable
      if (Test-Path -Path $RiskProHome) {
        # If RP_HOME exists and points to a different location
        if ($RiskProHome -ne $Properties.RPHomeDirectory) {
          Write-Log -Type "ERROR" -Object "The $($Properties.RiskProHomeVariable) is defined and points to a different installation ($RiskProHome)" -ExitCode 1
        }
      } else {
        # If RP_HOME is empty
        Write-Log -Type "WARN" -Object "The $($Properties.RiskProHomeVariable) is defined but points to an empty location"
        if (-Not $Unattended) {
          $Confirm = Confirm-Prompt -Prompt "Do you want to remove the deprecated $($Properties.RiskProHomeVariable) variable?"
        }
        if ($Confirm -Or $Unattended) {
          Remove-EnvironmentVariable -Name $Properties.RiskProHomeVariable
        }
      }
    }
    # Test database connection
    Write-Log -Type "INFO" -Object "Checking database server connectivity"
    $Check = Test-SQLConnection -Server $DatabaseProperties.DatabaseServerInstance -Database "master" -Credentials $DatabaseProperties.DBACredentials
    if (-Not $Check) {
      Write-Log -Type "ERROR" -Object "Unable to reach database server ($($DatabaseProperties.DatabaseServerInstance))" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Check sources
    # --------------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Checking distribution source files"
    $RiskProSource = Join-Path -Path $Properties.SrcDirectory -ChildPath $Properties.RiskProDistribution
    if (-Not (Test-Object -Path $RiskProSource)) {
      Write-Log -Type "ERROR" -Object "Path not found $RiskProSource" -ExitCode 1
    }
    # Check filesum
    if ($Properties.ChecksumCheck -eq "true") {
      Assert-Checksum -Properties $Properties -Type "RiskPro"
    } else {
      Write-Log -Type "WARN" -Object "Skipping source files integrity check"
    }
    # --------------------------------------------------------------------------
    # Setup application
    # --------------------------------------------------------------------------
    # Extract files
    Write-Log -Type "INFO" -Object "Extracting RiskPro to $($Properties.RPHomeDirectory)"
    Expand-CompressedFile -Path $RiskProSource -DestinationPath $Properties.InstallationPath -Force
    if (Test-Object -Path $Properties.RPHomeDirectory) {
      $Test = Get-ChildItem -Path $Properties.RPHomeDirectory | Out-String
      Write-Log -Type "DEBUG" -Object $Test
    } else {
      Write-Log -Type "ERROR" -Object "An error occured when extracting the files." -ExitCode 1
    }
    # Set environment variable
    if (Test-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope) {
      if ($RPHome -eq $Properties.RPHomeDirectory) {
        Write-Log -Type "WARN" -Object "$($Properties.RiskProHomeVariable) environment variable already exists"
      } else {
        Write-Log -Type "WARN" -Object "$($Properties.RiskProHomeVariable) environment variable already exists and points to a different location"
        $Continue = Confirm-Prompt -Prompt "Do you want to update it?"
        if ($Unattended -Or $Continue) {
          Set-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Value $Properties.RPHomeDirectory -Scope $Properties.EnvironmentVariableScope
          Write-Log -Type "CHECK" -Object "$($Properties.RiskProHomeVariable) environment variable has been updated"
        }
      }
    } else {
      Set-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Value $Properties.RPHomeDirectory -Scope $Properties.EnvironmentVariableScope
      Write-Log -Type "CHECK" -Object "$($Properties.RiskProHomeVariable) environment variable has been set"
    }
    # ----------------------------------------------------------------------
    # Setup database
    # ----------------------------------------------------------------------
    if (-Not $SkipDB) {
      # Create user and database
      Invoke-SetupDatabase -Properties ($Properties + $DatabaseProperties)
    }
    # Configure grid
    if ($Properties.CustomGridConfiguration -eq $true) {
      # TODO setup grid configuration from grid CSV files
    } else {
      foreach ($Server in $Servers) {
        # Get server properties
        $WebServer = $WebServers[$Server.Hostname]
        Invoke-GridSetup -Properties ($Properties + $DatabaseProperties +$WebServer) -Server $Server
      }
    }
    # ----------------------------------------------------------------------
    # Setup web-application
    # ----------------------------------------------------------------------
    # Setup security
    # TODO configure shiro.ini
    # Generate web-application
    Invoke-GenerateWebApp -Properties $Properties
    # ----------------------------------------------------------------------
    # Setup servers
    # ----------------------------------------------------------------------
    # Loop through the grid
    foreach ($Server in $Servers) {
      Write-Log -Type "INFO" -Object "Setup $($Server.Hostname) host"
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      # Encryption key
      $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
      # WildFly administration account
      $WildFlyAdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "WildFly administration user" -Unattended:$Unattended
      # Check web-server status
      Write-Log -Type "DEBUG" -Object "Check web-server status"
      $Running = Resolve-ServerState -Path $Properties.JBossClient -Controller ($WebServer.Hostname + ':' + $WebServer.AdminPort) -HTTPS:$Properties.EnableHTTPS
      if ($Running -eq $false) {
        Write-Log -Type "WARN" -Object "Web-Server $($Server.Hostname) is not running"
        if ($Attended) {
          $Confirm = Confirm-Prompt -Prompt "Do you want to start the web-server?"
        }
        if ($Unnattended -Or $Confirm) {
          # Start web-server
          Write-Log -Type "INFO" -Object "Start web-server"
          Start-WebServer -Properties ($Properties + $WebServer)
        }
      }
      # Configure web-server
      Invoke-SetupJBoss -Properties ($Properties + $DatabaseProperties + $WebServer) -Server $Server -Credentials $WildFlyAdminCredentials
      # Deploy web-application
      Invoke-DeployWebApp -Properties ($Properties + $DatabaseProperties + $WebServer) -Credentials $WildFlyAdminCredentials -Force
    }
    # ----------------------------------------------------------------------
    # Setup system model
    # ----------------------------------------------------------------------
    # Create system model
    Invoke-CreateModel -Properties $RiskProBatchClientProperties -Credentials $RiskProAdminCredentials -Name $Properties.SystemModelName -Type $Properties.SystemModelType -Description $Properties.SystemModelDescription -Currency $Properties.SystemModelCurrency -Template $Properties.SystemModelTemplate -Synchronous | Out-Null
    # ----------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "RiskPro has been successfully installed"
  }
}
