#Requires -Version 5.0
#Requires -RunAsAdministrator

<#
  .SYNOPSIS
  Deploy OneSumX for Risk Management

  .DESCRIPTION
  Setup and deploy OneSumX for Risk Management

  .PARAMETER Action
  The action parameter corresponds to the operation to perform.
  The following actions are available:
  - backup: Take a backup of RiskPro database
  - clean-up: Clean-up RiskPro application files
  - configure: Configure RiskPro
  - deploy: Deploy RiskPro web-application
  - extract: Extract RiskPro distribution files
  - install: Install and configure RiskPro
  - package: Generate RiskPro web-application (WAR file)
  - restore: Restore backup of RiskPro database
  - show: Display configuration
  - undeploy: Un-deploy RiskPro web-application
  - uninstall: Uninstall RiskPro
  - upgrade: Upgrade RiskPro

  .NOTES
  File name:      Deploy-RiskPro.ps1
  Author:         Florian CARRIER
  Creation date:  27/11/2018
  Last modified:  15/01/2020
  Dependencies:   - PowerShell Tool Kit (PSTK)
                  - WildFly PowerShell Module (PSWF)
                  - RiskPro PowerShell Module (PSRP)
                  - SQL Server PowerShell Module (SQLServer)

  .LINK
  https://svn.wkfs-frc.local/svn/PS/trunk/rp-deploy

  .LINK
  https://www.powershellgallery.com/packages/PSTK

  .LINK
  https://www.powershellgallery.com/packages/PSWF

  .LINK
  https://www.powershellgallery.com/packages/PSRP

  .LINK
  https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module
#>

# ------------------------------------------------------------------------------
# Parameters
# ------------------------------------------------------------------------------
[CmdletBinding (
  SupportsShouldProcess = $true
)]
Param (
  [Parameter (
    Position    = 1,
    Mandatory   = $true,
    HelpMessage = "Action to perform"
  )]
  [ValidateSet (
    "backup",
    "clean-up",
    "configure",
    "deploy",
    "extract",
    "install",
    "package",
    "restore",
    "show",
    "test",
    "undeploy",
    "uninstall",
    "upgrade"
  )]
  [String]
  $Action,
  [Parameter (
    Position    = 2,
    Mandatory   = $false,
    HelpMessage = "Specify a single target host from the grid"
  )]
  [String]
  $Target,
  [Parameter (
    Position    = 3,
    Mandatory   = $false,
    HelpMessage = "RiskPro version"
  )]
  [String]
  $Version,
  [Parameter (
    HelpMessage = "Flag to ignore database"
  )]
  [Switch]
  $SkipDB,
  [Parameter (
    HelpMessage = "Run script in unattended mode"
  )]
  [Switch]
  $Unattended
)

Begin {
  # ----------------------------------------------------------------------------
  # Global preferences
  # ----------------------------------------------------------------------------
  # $ErrorActionPreference = "Stop"
  $DebugPreference = "Continue"
  # Set-StrictMode -Version Latest

  # ----------------------------------------------------------------------------
  # Global variables
  # ----------------------------------------------------------------------------
  # General
  $WorkingDirectory   = $PSScriptRoot
  $ScriptName         = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
  $ISOTimeStamp       = Get-Date -Format "dd-MM-yyyy_HHmmss"
  # Configuration
  $LibDirectory       = Join-Path -Path $WorkingDirectory -ChildPath "lib"
  $ConfDirectory      = Join-Path -Path $WorkingDirectory -ChildPath "conf"
  $DefaultProperties  = Join-Path -Path $ConfDirectory    -ChildPath "default.ini"
  $CustomProperties   = Join-Path -Path $ConfDirectory    -ChildPath "custom.ini"

  # ----------------------------------------------------------------------------
  # Modules
  # ----------------------------------------------------------------------------
  $Modules = @("PSTK", "PSWF", "PSRP", "SQLServer")
  foreach ($Module in $Modules) {
    # Workaround for issue RPD-2
    $Force = $Module -ne "SQLServer"
    try {
      # Check if module is installed
      Import-Module -Name "$Module" -Force:$Force -ErrorAction "Stop"
      Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded."
    } catch {
      # If module is not installed then check if package is available locally
      try {
        Import-Module -Name (Join-Path -Path $LibDirectory -ChildPath $Module) -ErrorAction "Stop" -Force:$Force
        Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded from the library directory."
      } catch {
        Throw "The $Module library could not be loaded. Make sure it has been made available on the machine or manually put it in the ""$LibDirectory"" directory"
      }
    }
  }

  # ----------------------------------------------------------------------------
  # Script configuration
  # ----------------------------------------------------------------------------
  # General settings
  $Properties = Import-Properties -Path $DefaultProperties -Custom $CustomProperties
  # Resolve relative paths
  $Properties = Get-Path -PathToResolve $Properties.RelativePaths     -Hashtable $Properties -Root $WorkingDirectory
  $Properties = Set-RelativePath -Path $Properties.ResRelativePaths   -Hashtable $Properties -Root $Properties.ResDirectory
  $Properties = Set-RelativePath -Path $Properties.ConfRelativePaths  -Hashtable $Properties -Root $Properties.ConfDirectory
  $Properties = Set-RelativePath -Path $Properties.GridRelativePaths  -Hashtable $Properties -Root $Properties.GridDirectory
  $Properties = Set-RelativePath -Path $Properties.SQLRelativePaths   -Hashtable $Properties -Root $Properties.SQLDirectory

  # Resolve boolean values
  $BooleanValues = $Properties.BooleanValues.Split(",").Trim()
  foreach ($BooleanValue in $BooleanValues) {
    $Properties.$BooleanValue = Resolve-Boolean -Value $Properties.$BooleanValue
  }

  # ----------------------------------------------------------------------------
  # Start script
  # ----------------------------------------------------------------------------
  # Generate transcript
  $FormattedAction  = Format-String -String $Action -Format "TitleCase"
  $Transcript       = Join-Path -Path $Properties.LogDirectory -ChildPath "${FormattedAction}-RiskPro_${ISOTimeStamp}.log"
  Start-Script -Transcript $Transcript

  # Log command line
  Write-Log -Type "DEBUG" -Object $PSCmdlet.MyInvocation.Line

  # ----------------------------------------------------------------------------
  # Functions
  # ----------------------------------------------------------------------------
  # Load PowerShell functions
  $Functions = Get-ChildItem -Path $Properties.PSDirectory
  foreach ($Function in $Functions) {
    Write-Log -Type "DEBUG" -Object "Import $($Function.Name)"
    try   { . $Function.FullName }
    catch { Write-Error -Message "Failed to import function $($Function.FullName): $_" }
  }

  # ----------------------------------------------------------------------------
  # Properties
  # ----------------------------------------------------------------------------
  # Database properties
  $DatabaseProperties = Import-Properties -Path $Properties.DatabaseProperties
  # Hosts properties
  $WebServers = Import-Properties -Path $Properties.ServerProperties -Section
  # Grid configuration & server list
  if ($Target) {
    $Servers = Import-Csv -Path $Properties.CSVGridConfiguration -Delimiter "," | Where { $_.Hostname -eq $Target }
  } else {
    $Servers = Import-Csv -Path $Properties.CSVGridConfiguration -Delimiter ","
  }

  # Check grid configuration
  $GridCheck = Test-GridConfiguration -Grid $Servers -Properties $WebServers
  if (-Not $GridCheck) {
    Write-Log -Type "ERROR" -Object "Invalid grid configuration" -ExitCode 1
  }

  # Load custom grid configuration
  if ($Properties.CustomGridConfiguration -eq $true) {
    # General configuration
    $Properties.Add("RPConfiguration", (Import-CSVProperties -Path $Properties.CSVConfigurationProperties -Delimiter "," -Key "NAME" -NullValue "NULL"))
    # Environment configuration
    $Properties.Add("RPEnvironment", (Import-CSVProperties -Path $Properties.CSVEnvironmentProperties -Delimiter "," -Key "NAME" -NullValue "NULL"))
    # Job controller properties
    $Properties.Add("JobController", (Import-CSVProperties -Path $Properties.CSVJobControllerProperties -Delimiter "," -Key "HOSTNAME" -NullValue "NULL"))
    # Staging area properties
    $Properties.Add("StagingArea", (Import-CSVProperties -Path $Properties.CSVStagingAreaProperties -Delimiter "," -Key "HOSTNAME" -NullValue "NULL"))
    # TESS properties
    $Properties.Add("TESS", (Import-CSVProperties -Path $Properties.CSVTESSProperties -Delimiter "," -Key "HOSTNAME" -NullValue "NULL"))
    # Calculator properties
    $Properties.Add("Calculator", (Import-CSVProperties -Path $Properties.CSVCalculatorProperties -Delimiter "," -Key "NAME" -NullValue "NULL"))
  }

  # ----------------------------------------------------------------------------
  # Variables
  # ----------------------------------------------------------------------------
  # Execution type switch
  $Attended = -Not $Unattended

  # Version overwrite
  if ($PSBoundParameters.ContainsKey("Version")) {
    $Properties.RiskProVersion = $Version
  }

  # (Re)load environment variables
  Write-Log -Type "DEBUG" -Object "Load environment variables"
  $EnvironmentVariables = @(
    $Properties.RiskProHomeVariable,
    $Properties.WildFlyHomeVariable,
    $Properties.JavaHomeVariable
  )
  foreach ($EnvironmentVariable in $EnvironmentVariables) {
    Sync-EnvironmentVariable -Name $EnvironmentVariable -Scope $Properties.EnvironmentVariableScope | Out-Null
  }

  # RiskPro
  $Properties.RiskProDistribution = $Properties.DistributionPrefix + $Properties.RiskProVersion + $Properties.DistributionSuffix
  $RPHome                         = Get-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
  $Properties.RPHomeDirectory     = Join-Path -Path $Properties.InstallationPath -ChildPath ("rp-" + $Properties.RiskProVersion)

  # RiskPro migrator tool
  $Properties.MigratorDistribution = $Properties.RiskProMigratorPrefix + $Properties.RiskProMigratorVersion + $Properties.RiskProMigratorSuffix

  # Resolve relative paths
  $Properties = Set-RelativePath -Path $Properties.RPRelativePaths        -Hashtable $Properties -Root $Properties.RPHomeDirectory
  $Properties = Set-RelativePath -Path $Properties.RPBinRelativePaths     -Hashtable $Properties -Root $Properties.RPBinDirectory
  $Properties = Set-RelativePath -Path $Properties.RPLibRelativePaths     -Hashtable $Properties -Root $Properties.RPLibDirectory
  $Properties = Set-RelativePath -Path $Properties.RPWebAppRelativePaths  -Hashtable $Properties -Root $Properties.RPWebAppDirectory

  # WildFly
  # TODO Use specified JBOSS_HOME path if EnableEnvironmentVariable is set to 0
  if (Test-EnvironmentVariable -Name $Properties.WildFlyHomeVariable -Scope $Properties.EnvironmentVariableScope) {
    $JBossHome = Get-EnvironmentVariable -Name $Properties.WildFlyHomeVariable -Scope $Properties.EnvironmentVariableScope
    if (Test-Path -Path $JBossHome) {
      $Properties.JBossHome   = $JBossHome
      $Properties.JBossClient = Join-Path -Path $JBossHome -ChildPath "/bin/jboss-cli.ps1"
    } else {
      Write-Log -Type "ERROR" -Object "$($Properties.WildFlyHomeVariable) path not found ""$JBossHome""" -ExitCode 1
    }
  } else {
    Write-Log -Type "ERROR" -Object "$($Properties.WildFlyHomeVariable) environment variable does not exist" -ExitCode 1
  }

  # Database
  $DatabaseProperties.Add("DatabaseURL", (Get-ConnectionString -System $DatabaseProperties))
  if ($DatabaseProperties.DatabaseInstance) {
    $DatabaseProperties.Add("DatabaseServerInstance", $DatabaseProperties.DatabaseHost + "\" + $DatabaseProperties.DatabaseInstance)
  } else {
    $DatabaseProperties.Add("DatabaseServerInstance", $DatabaseProperties.DatabaseHost)
  }
  if ($DatabaseProperties.DatabaseType -eq "SQLServer") {
    $Properties.Add("DatabaseXML", $Properties.SQLServerXML)
    $DatabaseProperties.Add("DatabaseDriver"  , $Properties.SQLDriver           )
    $DatabaseProperties.Add("CommandLine"     , $Properties.SQLCommandLine      )
    $DatabaseProperties.Add("JDBCDriverModule", $Properties.SQLJDBCDriverModule )
    $DatabaseProperties.Add("JDBCDriverClass" , $Properties.SQLJDBCDriverClass  )
    $DatabaseProperties.Add("JDBCDriverPath"  , (Join-Path -Path $Properties.RPHomeDirectory -ChildPath $Properties.SQLJDBCDriverPath))
  } elseif ($DatabaseProperties.DatabaseType -eq "Oracle") {
    $Properties.Add("DatabaseXML", $Properties.OracleXML)
    $DatabaseProperties.Add("DatabaseDriver"  , $Properties.ORADriver           )
    $DatabaseProperties.Add("CommandLine"     , $Properties.ORACommandLine      )
    $DatabaseProperties.Add("JDBCDriverModule", $Properties.ORAJDBCDriverModule )
    $DatabaseProperties.Add("JDBCDriverClass" , $Properties.ORAJDBCDriverClass  )
    $DatabaseProperties.Add("JDBCDriverPath"  , (Join-Path -Path $Properties.RPHomeDirectory -ChildPath $Properties.ORAJDBCDriverPath))
  }

  # Get custom paths
  $CustomPathProperties = Import-Properties -Path $CustomProperties
  if ($CustomPathProperties.Count -ge 1) {
    $CustomPaths = Resolve-Array -Array $Properties.CustomPaths -Delimiter ","
    foreach ($CustomPath in $CustomPaths) {
      if (Find-Key -Hashtable $CustomPathProperties -Key $CustomPath) {
        if (Test-Object -Path $CustomPathProperties.$CustomPath -NotFound) {
          Write-Log -Type "DEBUG" -Object "Creating path $($CustomPathProperties.$CustomPath)"
          New-Item -ItemType "Directory" -Path $CustomPathProperties.$CustomPath -Force | Out-Null
        }
        $Properties.$CustomPath = $CustomPathProperties.$CustomPath
      }
    }
  }

  # RiskPro batch client properties
  $RiskProMainApplicationServer = Get-MainApplicationServer -Grid $Servers -Criteria "TESS"
  $RiskProBatchClientProperties = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
  $RiskProBatchClientProperties.Add("RiskProBatchClientPath", $Properties.RiskProBatchClient)
  $RiskProBatchClientProperties.Add("ServerURI", (Format-String -String (Get-URI -Scheme $WebServers.$RiskProMainApplicationServer.AppServerProtocol -Authority ($WebServers.$RiskProMainApplicationServer.Hostname + ':' + $WebServers.$RiskProMainApplicationServer.HTTPPort) -Path $Properties.RPWebApplication) -Format "lowercase"))
  $RiskProBatchClientProperties.Add("JavaHome", (Get-EnvironmentVariable -Name $Properties.JavaHomeVariable -Scope $Properties.EnvironmentVariableScope))
  $JavaOptions = @(
    '-Xmx2G'
    # WARNING use quotes to avoid parsing issue due to dots ("Could not find or load main class .io.tmpdir")
    '-D"java.io.tmpdir"="' + $Properties.RPTempDirectory + '"'
  )
  $RiskProBatchClientProperties.Add("JavaOptions", $JavaOptions)
}

Process {
  switch ($Action) {
    "install"   { Install-RiskPro   -Properties $Properties -Unattended:$Unattended -SkipDB:$SkipDB }
    "uninstall" { Uninstall-RiskPro -Properties $Properties -Unattended:$Unattended -SkipDB:$SkipDB }
    # --------------------------------------------------------------------------
    # Deployment of the web-application
    # --------------------------------------------------------------------------
    "deploy" {
      Write-Log -Type "INFO" -Object "Deploying $($Properties.RPWebApplication) application"
      # Loop through the grid
      foreach ($Server in $Servers) {
        # Get server properties
        $WebServer = $WebServers[$Server.Hostname]
        # WildFly administration account credentials
        $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        $WildFlyAdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "WildFly administration user" -Unattended:$Unattended
        # Deploy web-application
        Invoke-DeployWebApp -Properties ($Properties + $DatabaseProperties + $WebServer) -Credentials $WildFlyAdminCredentials -Force
      }
      Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application deployment complete"
    }
    # --------------------------------------------------------------------------
    # Undeployment of the web-application
    # --------------------------------------------------------------------------
    "undeploy" {
      Write-Log -Type "INFO" -Object "Undeploying $($Properties.RPWebApplication) application"
      # Loop through the grid
      foreach ($Server in $Servers) {
        # Get server properties
        $WebServer = $WebServers[$Server.Hostname]
        # WildFly administration account credentials
        $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        $WildFlyAdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "WildFly administration user" -Unattended:$Unattended
        # Deploy web-application
        Invoke-DeployWebApp -Properties ($Properties + $DatabaseProperties + $WebServer) -Credentials $WildFlyAdminCredentials -Undeploy
      }
      Write-Log -Type "CHECK" -Object "$($Properties.RPWebApplication) application undeployment complete"
    }
    # --------------------------------------------------------------------------
    # Packaging of the web-application
    # --------------------------------------------------------------------------
    "package" {
      # Generate web-application
      Invoke-GenerateWebApp -Properties $Properties
    }
    # --------------------------------------------------------------------------
    # Configure web-application server
    # --------------------------------------------------------------------------
    "configure" {
      # Loop through the grid
      foreach ($Server in $Servers) {
        # Get server properties
        $WebServer = $WebServers[$Server.Hostname]
        # Encryption key
        $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        # WildFly administration account
        $WildFlyAdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "WildFly administration user" -Unattended:$Unattended
        # Configure web-server
        Invoke-SetupJBoss -Properties ($Properties + $DatabaseProperties + $WebServer) -Server $Server -Credentials $WildFlyAdminCredentials
      }
    }
    # --------------------------------------------------------------------------
    # Clean-up files
    # --------------------------------------------------------------------------
    "clean-up" {
      # Remove RiskPro files without affecting the database
      Uninstall-RiskPro -Properties $Properties -Unattended:$Unattended -SkipDB
    }
    # --------------------------------------------------------------------------
    # Upgrade
    # --------------------------------------------------------------------------
    "upgrade" {
      # Check source files
      # TODO
      # ------------------------------------------------------------------------
      # Unpack RiskPro
      # ------------------------------------------------------------------------
      Write-Log -Type "INFO" -Object "Extracting RiskPro to $($Properties.RPHomeDirectory)"
      $RiskProSource = Join-Path -Path $Properties.SrcDirectory -ChildPath $Properties.RiskProDistribution
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
      # ------------------------------------------------------------------------
      # Unpack migrator
      # ------------------------------------------------------------------------
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
      # ------------------------------------------------------------------------
      # Security
      # ------------------------------------------------------------------------
      if ($Unattended) {
        # Use provided credentials
        Write-Log -Type "DEBUG" -Object "Use database credentials from configuration file"
        $DatabaseProperties.DBACredentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ($DatabaseProperties.DatabaseAdminUsername, (ConvertTo-SecureString -String $DatabaseProperties.DatabaseAdminPassword))
        $DatabaseProperties.RPDBCredentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ($DatabaseProperties.DatabaseUsername, (ConvertTo-SecureString -String $DatabaseProperties.DatabaseUserPassword))
      } else {
        # Prompt user for credentials
        Write-Log -Type "DEBUG" -Object "Prompt user for database credentials"
        $DatabaseProperties.DBACredentials  = Get-Credential -Message "Please enter the credentials for the database administrator user"
        $DatabaseProperties.RPDBCredentials = Get-Credential -Message "Please enter the credentials for the RiskPro database user"
      }
      # Default admin user for RiskPro
      $RiskProAdminCredentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ("admin", (ConvertTo-SecureString -String "01000000d08c9ddf0115d1118c7a00c04fc297eb01000000d47b2961e3b8c24d966a71cb16b199080000000002000000000003660000c000000010000000e0fa2246602ee662f42416f5abc44d540000000004800000a000000010000000807f367834387b4d85f8d52459154ae310000000698b32fe76413f7ef6e1568de1fa404e140000002a81e9e415efaf17daa8b7ae64e14ec291d66a34"))
      # ------------------------------------------------------------------------
      # Uninstall previous version
      # ------------------------------------------------------------------------
      # Undeploy web-application(s)
      foreach ($Server in $Servers) {
        $WebServer = $WebServers[$Server.Hostname]
        # Encryption key
        $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        # WildFly administration account
        $WildFlyAdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "WildFly administration user" -Unattended:$Unattended
        # TODO check that web-server is running
        Invoke-DeployWebApp -Properties ($Properties + $DatabaseProperties + $WebServer) -Credentials $WildFlyAdminCredentials -Undeploy
      }
      # Shutdown WildFly
      foreach ($Server in $Servers) {
        $WebServer = $WebServers[$Server.Hostname]
        Stop-WebServer -Properties ($Properties+ $DatabaseProperties + $WebServer)
        # TODO check that web-server is stopped
      }
      # ------------------------------------------------------------------------
      # Database migration
      # ------------------------------------------------------------------------
      # Backup database
      Backup-Schema -Properties ($Properties + $DatabaseProperties)
      # Run migrator
      $Properties.MigrationLog = Join-Path -Path $Properties.LogDirectory -ChildPath ("Migration_$($Properties.RiskProVersion)_$($ISOTimeStamp).log")
      $Upgrade = Update-RiskPro -Properties ($Properties + $DatabaseProperties + $MigratorProperties)
      # Check upgrade outcome
      if ($Upgrade -eq $true) {
        # ----------------------------------------------------------------------
        # Install new version
        # ----------------------------------------------------------------------
        # Generate web-application
        Invoke-GenerateWebApp -Properties $Properties
        # Deploy web-application(s)
        foreach ($Server in $Servers) {
          $WebServer = $WebServers[$Server.Hostname]
          # Start web-server
          Start-WebServer -Properties ($Properties + $DatabaseProperties + $WebServer)
          # TODO check that web-server has finished loading
          # Deploy web-application
          Invoke-DeployWebApp -Properties ($Properties + $DatabaseProperties + $WebServer)
        }
        # Clean-up
        Write-Log -Type "INFO" -Object "Removing old RiskPro files"
        if ($OldRiskProHome -ne $null) {
          # Check installation path
          if (Test-Object -Path $OldRiskProHome) {
            # Remove application files
            Write-Log -Type "DEBUG" -Object "Old RiskPro home location: $OldRiskProHome"
            Remove-Item -Path $OldRiskProHome -Recurse -Force -Confirm:$Attended
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
        # ----------------------------------------------------------------------
        # Roll-back
        # ----------------------------------------------------------------------
        Write-Log -Type "INFO" -Object "Rolling back upgrade"
        # Restore database from back-up
        Restore-Schema -Properties ($Properties + $DatabaseProperties)
        # Remove new application files
        Write-Log -Type "INFO" -Object "Remove new distribution files"
        # TODO
        # Reset RiskPro home environment variable
        Set-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Value $Properties.RPHomeDirectory -Scope $Properties.EnvironmentVariableScope
        Write-Log -Type "CHECK" -Object "Rollback complete"
      }
    }
    # --------------------------------------------------------------------------
    # Back-up database schema
    # --------------------------------------------------------------------------
    "backup" {
      # Security
      if ($Unattended) {
        # Use provided credentials
        Write-Log -Type "DEBUG" -Object "Use database credentials from configuration file"
        $DatabaseProperties.DBACredentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ($DatabaseProperties.DatabaseAdminUsername, (ConvertTo-SecureString -String $DatabaseProperties.DatabaseAdminPassword))
      } else {
        # Prompt user for credentials
        Write-Log -Type "DEBUG" -Object "Prompt user for database credentials"
        $DatabaseProperties.DBACredentials  = Get-Credential -Message "Please enter the credentials for the database administrator user"
      }
      # Back-up database schema
      Backup-Schema -Properties ($Properties + $DatabaseProperties)
    }
    # --------------------------------------------------------------------------
    # Restore database schema
    # --------------------------------------------------------------------------
    "restore" {
      # Security
      if ($Unattended) {
        # Use provided credentials
        Write-Log -Type "DEBUG" -Object "Use database credentials from configuration file"
        $DatabaseProperties.DBACredentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ($DatabaseProperties.DatabaseAdminUsername, (ConvertTo-SecureString -String $DatabaseProperties.DatabaseAdminPassword))
      } else {
        # Prompt user for credentials
        Write-Log -Type "DEBUG" -Object "Prompt user for database credentials"
        $DatabaseProperties.DBACredentials  = Get-Credential -Message "Please enter the credentials for the database administrator user"
      }
      # Test database connection
      Write-Log -Type "DEBUG" -Object "Test database connection"
      $SQLConnection = Test-SQLConnection -Server $DatabaseProperties.DatabaseServerInstance -Database "master" -Security -Credentials $DatabaseProperties.DBACredentials
      if ($SQLConnection -eq $true) {
        # Stop application
        foreach ($Server in $Servers) {
          $WebServer = $WebServers[$Server.Hostname]
          Stop-WebServer -Properties ($Properties + $DatabaseProperties + $WebServer)
        }
        # Retore database
        Restore-Schema -Properties ($Properties + $DatabaseProperties)
        # Re-start application
        foreach ($Server in $Servers) {
          $WebServer = $WebServers[$Server.Hostname]
          Start-WebServer -Properties ($Properties + $DatabaseProperties + $WebServer)
        }
      } else {
        Write-Log -Type "ERROR" -Object "Unable to reach database $($DatabaseProperties.DatabaseServerInstance)" -ExitCode 1
      }
    }
    # --------------------------------------------------------------------------
    # Show configuration
    # --------------------------------------------------------------------------
    "show" {
      # Display default x custom script configuration
      Write-Log -Type "INFO" -Object "Script configuration"
      Write-Host -Object ($Properties | Out-String).Trim() -ForegroundColor "Cyan"
      # Display database configuration
      Write-Log -Type "INFO" -Object "Database configuration"
      Write-Host -Object ($DatabaseProperties | Out-String).Trim() -ForegroundColor "Cyan"
      # Display environment (servers) configuration
      foreach ($WebServer in $WebServers.GetEnumerator()) {
        Write-Log -Type "INFO" -Object "$($WebServer.Key) host configuration"
        Write-Host -Object ($WebServer.Value | Out-String).Trim() -ForegroundColor "Cyan"
      }
      # Display RiskPro grid configuration
      Write-Log -Type "INFO" -Object "Grid configuration"
      Write-Host -Object ($Servers | Out-String).Trim() -ForegroundColor "Cyan"
    }
    # --------------------------------------------------------------------------
    # Sandbox
    # --------------------------------------------------------------------------
    "test" {
      # Loop through the grid
      foreach ($Server in $Servers) {
        # Get server properties
        $WebServer = $WebServers[$Server.Hostname]
        # WildFly administration account credentials
        $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
        $WildFlyAdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "WildFly administration user" -Unattended:$Unattended
        # Deploy web-application
        Get-DeploymentStatus -Path $Properties.JBossClient -Controller ($WebServer.Hostname + ':' + $WebServer.AdminPort) -Credentials $WildFlyAdminCredentials -Application "$($Properties.RPWebApplication).war"
      }
    }
    # --------------------------------------------------------------------------
    default {
      Write-Log -Type "ERROR" -Object "Unsupported action parameter: ""$Action""" -ExitCode 1
    }
  }
}

End {
  Stop-Script -ExitCode 0
}
