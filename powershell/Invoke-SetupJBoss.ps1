function Invoke-SetupJBoss {
  <#
    .SYNOPSIS
    Setup JBoss for RiskPro

    .DESCRIPTION
    Configure a JBoss (WildFly) instance for OneSumX for Risk Management

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER Server
    The server parameter corresponds to the properties of the server to configure.

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the WildFly instance administration account.

    .PARAMETER Remove
    The remove switch defines if the custom configuration should be removed from the WildFly instance.

    .INPUTS
    None. You cannot pipe objects to Invoke-SetupJBoss.

    .OUTPUTS
    None. Invoke-SetupJBoss does not return any object.

    .NOTES
    File name:      Invoke-SetupJBoss.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  14/01/2020
    WARNING         Do not use the RiskPro ANT client (see issue RPD-3)
  #>
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "System properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Server properties"
    )]
    [ValidateNotNullOrEmpty ()]
    # [System.Collections.Specialized.OrderedDictionary]
    $Server,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "User credentials"
    )]
    [ValidateNotNUllOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      HelpMessage = "Remove custom configuration"
    )]
    [Switch]
    $Remove
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Set properties
    $JavaProperties = Get-JavaProperties -Properties $Properties -Type "JBoss"
    $Redirection    = "2>&1"
    $Controller     = $Properties.Hostname + ':' + $Properties.AdminPort
    # Force-load JBOSS_HOME environment variable
    # TODO investigate why is it required in the script scope
    Sync-EnvironmentVariable -Name $Properties.WildFlyHomeVariable -Scope $Properties.EnvironmentVariableScope | Out-Null
  }
  Process {
    if ($Remove) {
      # ------------------------------------------------------------------------
      # Remove custom configuration
      # ------------------------------------------------------------------------
      # Unregister data-source
      Write-Log -Type "INFO" -Object "Unregistering $($Properties.DataSourceName) data-source"
      if (Test-DataSource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -DataSource $Properties.DataSourceName) {
        $RemoveDataSource = Remove-DataSource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -DataSource $Properties.DataSourceName
        Assert-JBossClientOutcome -Log $RemoveDataSource -Object "$($Properties.DataSourceName) data-source" -Verb "remove"
      } else {
        Write-Log -Type "WARN"  -Object "Data-source $($Properties.DataSourceName) is not registered"
      }
      # ------------------------------------------------------------------------
      # Remove custom web-server settings
      # TODO
      # ------------------------------------------------------------------------
      # Check if grid configuration exists
      Write-Log -Type "DEBUG" -Object "Check custom grid configuration"
      $GridResource = "/system-property=user.grid.properties.file"
      if (Test-Resource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Resource $GridResource) {
        # Remove grid configuration
        Write-Log -Type "INFO" -Object "Remove custom grid configuration"
        $RemoveGrid = Remove-Resource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Resource $GridResource
        Assert-JBossClientOutcome -Log $RemoveGrid -Object "Custom grid configuration" -Verb "remove"
      }
      # ------------------------------------------------------------------------
      # Check if custom log configuration exists
      Write-Log -Type "DEBUG" -Object "Check custom log configuration"
      $LogResource = "/system-property=riskpro.log4j.properties.file"
      if (Test-Resource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Resource $LogResource) {
        # Remove log configuration
        Write-Log -Type "INFO" -Object "Remove custom log properties"
        $RemoveLog = Remove-Resource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Resource $LogResource
        Assert-JBossClientOutcome -Log $RemoveLog -Object "Custom log configuration" -Verb "remove"
      }
      # ------------------------------------------------------------------------
      # Remove timeout configuration
      # TODO -DgeneralTimeout
      # ------------------------------------------------------------------------
      # Uninstall JDBC driver
      Write-Log -Type "INFO" -Object "Uninstalling $($Properties.DatabaseDriver) JDBC driver"
      if (Test-JDBCDriver -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Driver $Properties.DatabaseDriver) {
        # WARNING First remove data-source and reload to prevent issue "WFLYCTL0171: Removing services has lead to unsatisfied dependencies:Service jboss.jdbc-driver.mssql"
        Invoke-ReloadWildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Quiet
        $RemoveJDBCDriver = Remove-JDBCDriver -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Driver $Properties.DatabaseDriver
        Assert-JBossClientOutcome -Log $RemoveJDBCDriver -Object "$($Properties.DatabaseDriver) JDBC driver" -Verb "remove"
      } else {
        Write-Log -Type "WARN"  -Object "JDBC driver $($Properties.DatabaseDriver) is not installed"
      }
      # ------------------------------------------------------------------------
      # Uninstall custom database module
      Write-Log -Type "INFO" -Object "Uninstalling $($Properties.JDBCDriverModule) module"
      if (Test-Module -JBossHome $Properties.JBossHome -Module $Properties.JDBCDriverModule) {
        # WARNING Remove corresponding JDBC driver and reload WildFly to prevent resource lock
        Invoke-ReloadWildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Quiet
        $RemoveModule = Remove-Module -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Module $Properties.JDBCDriverModule
        if (Select-String -InputObject $RemoveModule -Pattern "Failed to delete" -SimpleMatch -Quiet) {
          # TODO fix file lock issue
          Write-Log -Type "WARN"  -Object "Module $($Properties.JDBCDriverModule) could not be uninstalled"
          # Write-Log -Type "ERROR" -Object $RemoveModule -ExitCode 1
          Write-Log -Type "ERROR" -Object $RemoveModule
        } elseif (Select-String -InputObject $RemoveModule -Pattern "Failed to locate module" -SimpleMatch -Quiet) {
          Write-Log -Type "WARN"  -Object "Module $($Properties.JDBCDriverModule) is not installed"
        } else {
          # TODO parse further
          Write-Log -Type "CHECK" -Object "Module $($Properties.JDBCDriverModule) uninstalled successfully"
        }
      } else {
        Write-Log -Type "WARN"  -Object "Module $($Properties.JDBCDriverModule) is not installed"
      }
    } else {
      # ------------------------------------------------------------------------
      # Configure web-server
      # ------------------------------------------------------------------------
      Write-Log -Type "INFO" -Object "Setup web-server settings"
      # Define attributes
      $ServerSettings = @(
        '/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-header-size,value=500000000)',
        '/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=max-post-size,value=500000000)',
        '/subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=max-header-size,value=500000000)',
        '/subsystem=undertow/server=default-server/https-listener=https:write-attribute(name=max-post-size,value=500000000)'
      )
      $SetupSettings = $true
      # Set settings
      foreach ($ServerSetting in $ServerSettings) {
        $SettingSetup = Invoke-JBossClient -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Command $ServerSetting
        if (-Not (Test-JBossClientOutcome -Log $SettingSetup)) {
          Write-Log -Type "ERROR" -Object $SettingSetup
          $SetupSettings = $false
        }
      }
      # Check outcome
      if ($SetupSettings -eq $true) {
        Write-Log -Type "CHECK" -Object "Web-server configured successfully"
      } else {
        Write-Log -Type "ERROR" -Object "Web-server configuration failed" -ExitCode 1
      }

      # ------------------------------------------------------------------------
      # Add SQL JDBC module
      Write-Log -Type "INFO" -Object "Install $($Properties.JDBCDriverModule) module"
      # TODO fix error "WFLYJCA0041: Failed to load module for driver [mssql.jdbc]"
      $AddModule = Add-Module -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Module $Properties.JDBCDriverModule -Resources $Properties.JDBCDriverPath -Dependencies $Properties.JDBCDriverDependency
      # Check outcome
      if (Test-Module -JBossHome $Properties.JBossHome -Module $Properties.JDBCDriverModule) {
        Write-Log -Type "CHECK" -Object "$($Properties.JDBCDriverModule) module successfully installed"
      } else {
        Write-Log -Type "WARN"  -Object "$($Properties.JDBCDriverModule) module could not be installed"
        Write-Log -Type "ERROR" -Object "$AddModule" -ExitCode 1
      }
      # Install JDBC driver
      Write-Log -Type "INFO" -Object "Install $($Properties.DatabaseDriver) JDBC driver"
      $AddJDBCDriver = Add-JDBCDriver -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Driver $Properties.DatabaseDriver -Module $Properties.JDBCDriverModule -Class $Properties.JDBCDriverClass
      Assert-JBossClientOutcome -Log $AddJDBCDriver -Object "$($Properties.DatabaseDriver) JDBC driver" -Verb "install"
      # ------------------------------------------------------------------------
      # Register data-source
      Write-Log -Type "INFO" -Object "Register $($Properties.DataSourceName) data-source"
      $AddDataSource = Add-DataSource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -DataSource $Properties.DataSourceName -Driver $Properties.DatabaseDriver -ConnectionURL $Properties.DatabaseURL -UserName $Properties.RPDBCredentials.UserName -Password $Properties.RPDBCredentials.GetNetworkCredential().Password
      Assert-JBossClientOutcome -Log $AddDataSource -Object "$($Properties.DataSourceName) data-source" -Verb "register"
      # ------------------------------------------------------------------------
      # Setup grid property
      Write-Log -Type "INFO" -Object "Configure grid properties"
      $UserGridPath     = Set-GridProperties -Properties $Properties -Server $Server
      $UserGridURI      = Resolve-URI -URI $UserGridPath
      $UserGridResource = "/system-property=user.grid.properties.file"
      # Check if grid configuration already exists
      if (Test-Resource -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Resource $UserGridResource) {
        Write-Log -Type "WARN" -Object "Overwritting existing grid configuration"
        # Clean-up existing configuration
        $RemoveGridCmd = "$($UserGridResource):remove()"
        $RemoveGridLog = Invoke-JBossClient -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Command $RemoveGridCmd
        if (Assert-JBossClientOutcome -Log $RemoveGridLog -Object "user grid property" -Verb "remove" -Quiet) {
          Write-Log -Type "DEBUG" -Object "User grid property successfully removed"
        } else {
          Write-Log -Type "ERROR" -Object "An error occurred while overwritting the existing user grid configuration" -ExitCode 1
        }
      }
      # Add new grid configuration
      $GridSetupCmd = "/system-property=user.grid.properties.file:add(value=""$UserGridURI"")"
      Write-Log -Type "DEBUG" -Object $GridSetupCmd
      $GridSetupLog = Invoke-JBossClient -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Command $GridSetupCmd
      Assert-JBossClientOutcome -Log $GridSetupLog -Object "Grid properties" -Verb "set" -Irregular "set" -Plural
      # --------------------------------------------------------------------------
      # Setup logs
      Write-Log -Type "INFO" -Object "Configure log properties"
      $LogPropertiesPath  = Set-LogProperties -Properties $Properties -Server $Server
      $LogPropertiesURI   = Resolve-URI -URI $LogPropertiesPath
      # Check if log configuration already exists
      $CheckLogCmd = "/system-property=riskpro.log4j.properties.file:read-resource()"
      Write-Log -Type "DEBUG" -Object $CheckLogCmd
      $CheckLogLog =  Invoke-JBossClient -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Command $CheckLogCmd
      if (Assert-JBossClientOutcome  -Log $CheckLogLog -Object "Log4J properties" -Verb "exist" -Quiet) {
        Write-Log -Type "WARN" -Object "Overwritting existing log configuration"
        # Clean-up existing configuration
        $RemoveLogCmd = "/system-property=riskpro.log4j.properties.file:remove()"
        $RemoveLogLog = Invoke-JBossClient -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Command $RemoveLogCmd
        if (Assert-JBossClientOutcome -Log $RemoveLogLog -Object "Log4J properties" -Verb "remove" -Quiet) {
          Write-Log -Type "DEBUG" -Object "Log4J properties successfully removed"
        } else {
          Write-Log -Type "ERROR" -Object "An error occurred while overwritting the existing Log4J configuration" -ExitCode 1
        }
      }
      # TODO TODO TODO
      # Add new log configuration
      $LogSetupCmd = "/system-property=riskpro.log4j.properties.file:add(value=""$LogPropertiesURI"")"
      $LogSetupLog = Invoke-JBossClient -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials -Command $LogSetupCmd
      Assert-JBossClientOutcome -Log $LogSetupLog -Object "Log properties" -Verb "set" -Irregular "set" -Plural
      # --------------------------------------------------------------------------
      # Setup timeout
      # TODO -DgeneralTimeout
    }
    # --------------------------------------------------------------------------
    # Reload web-server
    Invoke-ReloadWildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $Credentials
  }
  End {
    if ($Remove) {
      Write-Log -Type "CHECK" -Object "$($Server.Hostname) web-server de-configuration complete"
    } else {
      Write-Log -Type "CHECK" -Object "$($Server.Hostname) web-server configuration complete"
    }
  }
}
