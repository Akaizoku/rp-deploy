function Update-RiskPro {
  <#
    .SYNOPSIS
    Update RiskPro

    .DESCRIPTION
    Upgrade the OneSumX for Risk Management application

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER WebServers
    The web-servers parameter corresponds to the configuration of the application servers.

    .PARAMETER Servers
    The servers parameter corresponds to the configuration of the server grid.

    .EXAMPLE
    Update-RiskPro -Properties $Properties

    .NOTES
    File name:      Update-RiskPro.ps1
    Author:         Florian Carrier
    Creation date:  25/11/2019
    Last modified:  22/01/2020
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
    # Execution type switch
    $Attended = -Not $Unattended
  }
  Process {
    Write-Log -Type "INFO" -Object "Upgrading RiskPro to version $($Properties.RiskProVersion)"
    # --------------------------------------------------------------------------
    # Checks
    # --------------------------------------------------------------------------
    # Check source files
    # TODO
    # Encryption key
    $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
    # Database system administrator credentials
    $Properties.DBACredentials = Get-ScriptCredentials -UserName $Properties.DatabaseAdminUsername -Password $Properties.DatabaseAdminPassword -EncryptionKey $EncryptionKey -Label "database system administrator" -Unattended:$Unattended
    # RiskPro database user credentials
    $Properties.RPDBCredentials = Get-ScriptCredentials -UserName $Properties.DatabaseUsername -Password $Properties.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro database user" -Unattended:$Unattended
    # Set database properties
    $DatabaseProperties = Get-JavaProperties -Properties $Properties -Type "Database"
    # Test database connection
    Write-Log -Type "INFO" -Object "Checking database server connectivity"
    $DatabaseConnection = Test-SQLConnection -Server $Properties.DatabaseServerInstance -Database "master" -Credentials $Properties.DBACredentials
    if (-Not $DatabaseConnection) {
      Write-Log -Type "ERROR" -Object "Unable to reach database server ($($Properties.DatabaseServerInstance))" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Unpack RiskPro
    # --------------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Extracting RiskPro to $($Properties.RPHomeDirectory)"
    $RiskProSource = Join-Path -Path $Properties.SrcDirectory -ChildPath $Properties.RiskProDistribution
    # TODO check if path already exists
    Expand-CompressedFile -Path $RiskProSource -DestinationPath $Properties.InstallationPath -Force
    if (Test-Object -Path $Properties.RPHomeDirectory) {
      $Test = Get-ChildItem -Path $Properties.RPHomeDirectory | Out-String
      Write-Log -Type "DEBUG" -Object $Test
    } else {
      Write-Log -Type "ERROR" -Object "An error occured when extracting the files." -ExitCode 1
    }
    # Set environment variable
    Write-Log -Type "INFO" -Object "Setting-up $($Properties.RiskProHomeVariable) environment variable"
    if (Test-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope) {
      $OldRiskProHome = Get-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
      if ($OldRiskProHome -eq $Properties.RPHomeDirectory) {
        Write-Log -Type "WARN" -Object "$($Properties.RiskProHomeVariable) environment variable already exists"
      } else {
        Set-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Value $Properties.RPHomeDirectory -Scope $Properties.EnvironmentVariableScope
        Write-Log -Type "CHECK" -Object "$($Properties.RiskProHomeVariable) environment variable has been updated"
      }
    } else {
      Write-Log -Type "WARN" -Object "$($Properties.RiskProHomeVariable) environment variable was not set"
      Write-Log -Type "CHECK" -Object "$($Properties.RiskProHomeVariable) environment variable has been created"
      Set-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Value $Properties.RPHomeDirectory -Scope $Properties.EnvironmentVariableScope
    }
    # Save RiskPro home location
    $RiskProHome = Get-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
    # --------------------------------------------------------------------------
    # Unpack migrator
    # --------------------------------------------------------------------------
    $MigratorDistribution = $Properties.RiskProMigratorPrefix + $Properties.RiskProMigratorVersion + $Properties.RiskProMigratorSuffix
    $MigratorSource       = Join-Path -Path $Properties.SrcDirectory    -ChildPath $MigratorDistribution
    $MigratorDestination  = Join-Path -Path $Properties.RPHomeDirectory -ChildPath "etc/migrator"
    # Check source files
    if (Test-Path -Path $MigratorSource) {
      # TODO Check distribution files integrity
      # Extract distribution files
      Write-Log -Type "INFO" -Object "Extracting migrator tool"
      Expand-CompressedFile -Path $MigratorSource -DestinationPath $MigratorDestination -Force
      if (Test-Object -Path $MigratorDestination) {
        $Test = Get-ChildItem -Path $MigratorDestination | Out-String
        Write-Log -Type "DEBUG" -Object $Test
      } else {
        Write-Log -Type "ERROR" -Object "An error occured when extracting the files." -ExitCode 1
      }
    } else {
      Write-Log -Type "ERROR" -Object "Path not found $MigratorSource" -ExitCode 1
    }
    # Define RiskPro Migrator tool properties
    $MigratorProperties = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
    $MigratorToolPath   = Get-ChildItem -Path (Join-Path -Path $RiskProHome -ChildPath "etc\migrator") -Filter "migrator-$($Properties.RiskProMigratorVersion)-launcher.jar"
    $MigratorProperties.Add('MigratorToolPath', $MigratorToolPath.FullName)
    $MigratorProperties.Add("JavaHome"        , (Get-EnvironmentVariable -Name $Properties.JavaHomeVariable -Scope $Properties.EnvironmentVariableScope))
    $MigratorProperties.Add("JavaOptions"     , $JavaOptions)
    # --------------------------------------------------------------------------
    # Security
    # --------------------------------------------------------------------------
    # Encryption key
    $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
    # Database system administrator credentials
    $Properties.DBACredentials = Get-ScriptCredentials -UserName $Properties.DatabaseAdminUsername -Password $Properties.DatabaseAdminPassword -EncryptionKey $EncryptionKey -Label "database system administrator" -Unattended:$Unattended
    # RiskPro database user credentials
    $Properties.RPDBCredentials = Get-ScriptCredentials -UserName $Properties.DatabaseUsername -Password $Properties.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro database user" -Unattended:$Unattended
    # Default admin user for RiskPro (force unattended flag to use value from default configuration file)
    $RiskProAdminCredentials = Get-ScriptCredentials -UserName "admin" -Password $Properties.DefaultAdminPassword -EncryptionKey $EncryptionKey -Label "RiskPro administration user" -Unattended
    # --------------------------------------------------------------------------
    # Undeploy previous version
    # --------------------------------------------------------------------------
    Invoke-UndeployRiskPro -Properties $Properties -WebServers $WebServers -Servers $Servers -Unattended:$Unattended
    # --------------------------------------------------------------------------
    # Database back-up
    # --------------------------------------------------------------------------
    # Disable data-sources
    Write-Log -Type "INFO" -Object "Disable data-sources"
    foreach ($Server in $Servers) {
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      # Controller
      $Controller = $WebServer.Hostname + ':' + $WebServer.AdminPort
      # Application server administration account credentials
      $EncryptionKey    = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
      $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($WebServer.WebServerType) administration user" -Unattended:$Unattended
      # Disable data-source
      $DisableDataSource = Disable-DataSource -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials -DataSource $Properties.DataSourceName
      Assert-JBossClientOutcome -Log $DisableDataSource -Object "$($Properties.DataSourceName) on host $($Server.Hostname)" -Verb "disable"
      # Reload server
      Invoke-ReloadWildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials
    }
    # Kill database sessions
    Write-Log -Type "INFO" -Object "Close open database connexions"
    $KillSession = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.DatabaseXML -Operation "killUserSession" -Properties $DatabaseProperties
    Assert-RiskProANTOutcome -Log $KillSession -Object "User sessions" -Verb "close" -Plural
    # Check backup directory
    if (Test-Object -Path $Properties.RPBackupDirectory -NotFound) {
      New-Item -Path $Properties.RPBackupDirectory -ItemType "Directory" -Force
    }
    # Create database back-up
    Invoke-BackupSchema -Properties $Properties -Unattended:$Unattended
    # --------------------------------------------------------------------------
    # Database migration
    # --------------------------------------------------------------------------
    # Run migrator
    $Properties.MigrationLog = Join-Path -Path $Properties.LogDirectory -ChildPath ("Migration_$($Properties.RiskProVersion)_$($ISOTimeStamp).log")
    $Upgrade = Invoke-MigrateDatabase -Properties ($Properties + $MigratorProperties)
    # Check upgrade outcome
    if ($Upgrade -eq $true) {
      # ------------------------------------------------------------------------
      # Install new version
      # ------------------------------------------------------------------------
      # Generate web-application
      Invoke-GenerateWebApp -Properties $Properties
      # Re-enable data-source
      Write-Log -Type "INFO" -Object "Enabling data-sources"
      foreach ($Server in $Servers) {
        # Get server properties
        $WebServer = $WebServers[$Server.Hostname]
        # Controller
        $Controller = $WebServer.Hostname + ':' + $WebServer.AdminPort
        # Application server administration account credentials
        $EncryptionKey    = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($WebServer.WebServerType) administration user" -Unattended:$Unattended
        $EnableDataSource = Enable-DataSource -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials -DataSource $Properties.DataSourceName
        Assert-JBossClientOutcome -Log $EnableDataSource -Object "$($Properties.DataSourceName) on host $($Server.Hostname)" -Verb "enable"
        # Reload server
        Invoke-ReloadWildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials
      }
      # Deploy web-application(s)
      Invoke-DeployRiskPro -Properties $Properties -WebServers $WebServers -Servers $Servers -Unattended:$Unattended
      # Clean-up
      Write-Log -Type "INFO" -Object "Removing old RiskPro files"
      if ($OldRiskProHome -ne $null) {
        # Check installation path
        if (Test-Object -Path $OldRiskProHome) {
          # Remove application files
          Write-Log -Type "DEBUG" -Object "Old RiskPro home location: $OldRiskProHome"
          Remove-Item -Path $OldRiskProHome -Recurse -Force -Confirm:$Attended -ErrorAction "SilentlyContinue" -ErrorVariable $RemovalErrors
          # Check errors
          if ($RemovalErrors) {
            foreach ($RemovalError in $RemovalErrors) {
              Write-Log -Type "DEBUG" -Object $RemovalError
            }
            Write-Log -Type "ERROR" -Object "Some files could not be removed"
            Write-Log -Type "WARN"  -Object "Please check and manually clear $RiskProHome"
          }
          # Check if directory has successfully been removed
          if (Test-Object -Path $OldRiskProHome) {
            Write-Log -Type "ERROR" -Object "An error occured while attempting removing the files" -ExitCode 1
          }
        } else {
          Write-Log -Type "ERROR" -Object "Cannot find path $OldRiskProHome because it does not exist." -ExitCode 1
        }
      } else {
        Write-Log -Type "ERROR" -Object "Unable to locate previous RiskPro installation location" -ExitCode 1
      }
      Write-Log -Type "CHECK" -Object "RiskPro upgrade completed successfully"
    } else {
      # ------------------------------------------------------------------------
      # Roll-back
      # ------------------------------------------------------------------------
      Write-Log -Type "INFO" -Object "Rolling back upgrade"
      # Restore database from back-up
      Invoke-RestoreSchema -Properties $Properties -Unattended:$Unattended
      # Re-enable data-source
      Write-Log -Type "INFO" -Object "Enabling data-sources"
      foreach ($Server in $Servers) {
        # Get server properties
        $WebServer = $WebServers[$Server.Hostname]
        # Controller
        $Controller = $WebServer.Hostname + ':' + $WebServer.AdminPort
        # Application server administration account credentials
        $EncryptionKey    = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($WebServer.WebServerType) administration user" -Unattended:$Unattended
        $EnableDataSource = Enable-DataSource -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials -DataSource $Properties.DataSourceName
        Assert-JBossClientOutcome -Log $EnableDataSource -Object "$($Properties.DataSourceName) on host $($Server.Hostname)" -Verb "enable"
        # Reload server
        Invoke-ReloadWildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials
      }
      # Re-deploy web-application(s)
      $Properties.RPWebAppDirectory = Join-Path $OldRiskProHome -ChildPath "webapp"
      Invoke-DeployRiskPro -Properties $Properties -WebServers $WebServers -Servers $Servers -Unattended:$Unattended
      # Remove new application files
      Write-Log -Type "INFO" -Object "Remove RiskPro $($Properties.RiskProVersion) distribution files"
      # TODO
      Remove-Item -Path $RiskProHome -Recurse -Force -Confirm:$Attended -ErrorAction "SilentlyContinue" -ErrorVariable $RemovalErrors
      # Check errors
      if ($RemovalErrors) {
        foreach ($RemovalError in $RemovalErrors) {
          Write-Log -Type "DEBUG" -Object $RemovalError
        }
        Write-Log -Type "ERROR" -Object "Some files could not be removed"
        Write-Log -Type "WARN"  -Object "Please check and manually clear $RiskProHome"
      }
      # Check if directory has been correctly removed
      if (Test-Object -Path $RiskProHome) {
        Write-Log -Type "ERROR" -Object "An error occured while attempting removing the files" -ExitCode 1
      }
      # Reset RiskPro home environment variable
      Set-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Value $OldRiskProHome -Scope $Properties.EnvironmentVariableScope
      Write-Log -Type "CHECK" -Object "Rollback complete"
      Write-Log -Type "ERROR" -Object "Migration failed" -ExitCode 1
    }
  }
}
