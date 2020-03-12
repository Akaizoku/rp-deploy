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
  - backup:     Take a backup of RiskPro database
  - clean-up:   Clean-up RiskPro application files
  - configure:  Configure RiskPro
  - deploy:     Deploy RiskPro web-application
  - extract:    Extract RiskPro distribution files
  - install:    Install and configure RiskPro
  - package:    Generate RiskPro web-application (WAR file)
  - restore:    Restore backup of RiskPro database
  - show:       Display configuration
  - undeploy:   Un-deploy RiskPro web-application
  - uninstall:  Uninstall RiskPro
  - upgrade:    Upgrade RiskPro

  .PARAMETER Version
  The optional version parameter allows to overwrite the application version defined in the configuration file.

  .PARAMETER Unattended
  The unattended switch define if the script should run in silent mode without any user interaction.

  .NOTES
  File name:      Deploy-RiskPro.ps1
  Author:         Florian CARRIER
  Creation date:  27/11/2018
  Last modified:  11/03/2020
  Dependencies:   - PowerShell Tool Kit (PSTK)
                  - WildFly PowerShell Module (PSWF)
                  - RiskPro PowerShell Module (PSRP)
                  - SQL Server PowerShell Module (SQLServer)

  .LINK
  https://github.com/Akaizoku/rp-deploy

  .LINK
  https://www.powershellgallery.com/packages/PSTK

  .LINK
  https://www.powershellgallery.com/packages/PSWF

  .LINK
  https://www.powershellgallery.com/packages/PSRP

  .LINK
  https://docs.microsoft.com/en-us/sql/powershell/download-sql-server-ps-module

  .LINK
  http://wolterskluwerfs.com

  .LINK
  http://www.wolterskluwerfs.com/risk/home.aspx
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
  # WARNING Do not enable strict mode to prevent
  # Set-StrictMode -Version Latest
  # $ErrorActionPreference  = "Stop"
  $DebugPreference        = "Continue"

  # ----------------------------------------------------------------------------
  # Global variables
  # ----------------------------------------------------------------------------
  # General
  $WorkingDirectory   = $PSScriptRoot
  $ISOTimeStamp       = Get-Date -Format "yyyy-MM-dd_HHmmss"

  # Configuration
  $LibDirectory       = Join-Path -Path $WorkingDirectory -ChildPath "lib"
  $ConfDirectory      = Join-Path -Path $WorkingDirectory -ChildPath "conf"
  $DefaultProperties  = Join-Path -Path $ConfDirectory    -ChildPath "default.ini"
  $CustomProperties   = Join-Path -Path $ConfDirectory    -ChildPath "custom.ini"

  # ----------------------------------------------------------------------------
  # Modules
  # ----------------------------------------------------------------------------
  $Modules = @("PSTK", "PSWF", "PSRP")
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
  $Properties.RiskProDistribution = "distribution-" + $Properties.RiskProVersion + "-dist.zip"
  $RPHome                         = Get-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
  $Properties.RPHomeDirectory     = Join-Path -Path $Properties.InstallationPath -ChildPath ("rp-" + $Properties.RiskProVersion)

  # RiskPro migrator tool
  $Properties.MigratorDistribution = "migrator-distribution-" + $Properties.RiskProMigratorVersion + ".zip"

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

  # Database properties
  if ($DatabaseProperties.DatabaseInstance) {
    $DatabaseProperties.Add("DatabaseURL", (Get-ConnectionString -Type $DatabaseProperties.DatabaseType -Hostname $DatabaseProperties.DatabaseHost -PortNumber $DatabaseProperties.DatabasePort -Instance $DatabaseProperties.DatabaseInstance -Database $DatabaseProperties.DatabaseName -Connector "JDBC"))
  } else {
    $DatabaseProperties.Add("DatabaseURL", (Get-ConnectionString -Type $DatabaseProperties.DatabaseType -Hostname $DatabaseProperties.DatabaseHost -PortNumber $DatabaseProperties.DatabasePort -Database $DatabaseProperties.DatabaseName -Connector "JDBC"))
  }
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
    # Load SQLServer module
    $Modules = @("SQLServer")
    foreach ($Module in $Modules) {
      try {
        # Check if module is installed
        Import-Module -Name "$Module" -ErrorAction "Stop"
        Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded."
      } catch {
        # If module is not installed then check if package is available locally
        try {
          Import-Module -Name (Join-Path -Path $LibDirectory -ChildPath $Module) -ErrorAction "Stop"
          Write-Log -Type "CHECK" -Object "The $Module module was successfully loaded from the library directory."
        } catch {
          Throw "The $Module library could not be loaded. Make sure it has been made available on the machine or manually put it in the ""$LibDirectory"" directory"
        }
      }
    }
  } elseif ($DatabaseProperties.DatabaseType -eq "Oracle") {
    $Properties.Add("DatabaseXML", $Properties.OracleXML)
    $DatabaseProperties.Add("DatabaseDriver"  , $Properties.ORADriver           )
    $DatabaseProperties.Add("CommandLine"     , $Properties.ORACommandLine      )
    $DatabaseProperties.Add("JDBCDriverModule", $Properties.ORAJDBCDriverModule )
    $DatabaseProperties.Add("JDBCDriverClass" , $Properties.ORAJDBCDriverClass  )
    $DatabaseProperties.Add("JDBCDriverPath"  , (Join-Path -Path $Properties.RPHomeDirectory -ChildPath $Properties.ORAJDBCDriverPath))
    # Load Oracle Managed Data Access assembly
    if ($Properties.OracleManagedDataAccess -And (Test-Path -Path $Properties.OracleManagedDataAccess)) {
      Add-Type -Path $Properties.OracleManagedDataAccess
    } else {
      Write-Log -Type "ERROR" -Object "Oracle.ManagedDataAccess assembly not found" -ExitCode 1
    }
  }

  # Get custom paths
  $Properties.CustomProperties = $CustomProperties
  $CustomCheck = Import-Properties -Path $Properties.CustomProperties
  $CustomPaths = Resolve-Array -Array $Properties.CustomPaths -Delimiter ","
  foreach ($CustomPath in $CustomPaths) {
    # Check that path has not been specified by user
    if ($CustomCheck.$CustomPath -eq $null) {
      # Resolve absolute path
      $Properties.$CustomPath = Join-Path -Path $Properties.InstallationPath -ChildPath $Properties.$CustomPath
    }
  }

  # Java
  if ((-Not $Properties.JavaPath) -Or ($Properties.JavaPath -eq "") -Or ($Properties.JavaPath -eq $null)) {
    if (Test-EnvironmentVariable -Name $Properties.JavaHomeVariable -Scope $Properties.EnvironmentVariableScope) {
      Write-Log -Type "DEBUG" -Object "Java path not specified. Defaulting to $($Properties.JavaHomeVariable)"
      $JavaHome = Get-EnvironmentVariable -Name $Properties.JavaHomeVariable -Scope $Properties.EnvironmentVariableScope
      $Properties.JavaPath = Join-Path -Path $JavaHome -ChildPath "bin\java.exe"
    } else {
      Write-Log -Type "ERROR" -Object "$($Properties.JavaHomeVariable) environment variable does not exist"
      Write-Log -Type "WARN"  -Object "Please setup $($Properties.JavaHomeVariable) or specify the Java path in the configuration files" -ExitCode 1
    }
  }

  # RiskPro batch client properties
  $RiskProMainApplicationServer = Get-MainApplicationServer -Grid $Servers -Criteria "TESS"
  $RiskProBatchClientProperties = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
  $RiskProBatchClientProperties.Add("RiskProBatchClientPath", $Properties.RiskProBatchClient)
  $RiskProBatchClientProperties.Add("ServerURI", (Format-String -String (Get-URI -Scheme $WebServers.$RiskProMainApplicationServer.AppServerProtocol -Authority ($WebServers.$RiskProMainApplicationServer.Hostname + ':' + $WebServers.$RiskProMainApplicationServer.HTTPPort) -Path $Properties.RPWebApplication) -Format "lowercase"))
  $JavaOptions = New-Object -TypeName "System.Collections.ArrayList"
  # WARNING use quotes to avoid parsing issue due to dots ("Could not find or load main class .io.tmpdir")
  [Void]$JavaOptions.Add('-D"java.io.tmpdir"="' + $Properties.RPTempDirectory + '"')
  # Add heap size if specified
  if ($Properties.HeapSize) { [Void]$JavaOptions.Add('-Xmx' + $Properties.HeapSize) }
  $RiskProBatchClientProperties.Add("JavaOptions", $JavaOptions)
}
# ------------------------------------------------------------------------------
Process {
  switch ($Action) {
    "backup"    { Invoke-BackupSchema     -Properties ($Properties + $DatabaseProperties)                                           -Unattended:$Unattended                 }
    "clean-up"  { Clear-RiskPro           -Properties $Properties                                                                   -Unattended:$Unattended                 }
    "configure" { Invoke-ConfigureRiskPro -Properties ($Properties + $DatabaseProperties) -WebServers $WebServers -Servers $Servers -Unattended:$Unattended -SkipDB:$SkipDB }
    "deploy"    { Invoke-DeployRiskPro    -Properties $Properties                         -WebServers $WebServers -Servers $Servers -Unattended:$Unattended                 }
    "install"   { Install-RiskPro         -Properties ($Properties + $DatabaseProperties) -WebServers $WebServers -Servers $Servers -Unattended:$Unattended -SkipDB:$SkipDB }
    "package"   { Invoke-GenerateWebApp   -Properties $Properties                                                                                                           }
    "restore"   { Invoke-RestoreSchema    -Properties ($Properties + $DatabaseProperties)                                           -Unattended:$Unattended                 }
    "show"      { Show-Configuration      -Properties $Properties -DatabaseProperties $DatabaseProperties -WebServers $WebServers -Servers $Servers                         }
    "test"      { Test-RiskPro            -Properties $Properties -RiskProBatchClientProperties $RiskProBatchClientProperties       -Unattended:$Unattended                 }
    "undeploy"  { Invoke-UndeployRiskPro  -Properties $Properties                         -WebServers $WebServers -Servers $Servers -Unattended:$Unattended                 }
    "uninstall" { Uninstall-RiskPro       -Properties ($Properties + $DatabaseProperties) -WebServers $WebServers -Servers $Servers -Unattended:$Unattended -SkipDB:$SkipDB }
    "upgrade"   { Update-RiskPro          -Properties ($Properties + $DatabaseProperties) -WebServers $WebServers -Servers $Servers -Unattended:$Unattended                 }
    default     { Write-Log -Type "ERROR" -Object "Unsupported action parameter: ""$Action""" -ExitCode 1                                                                   }
  }
}
# ------------------------------------------------------------------------------
End {
  # End script gracefully
  Stop-Script -ExitCode 0
}
