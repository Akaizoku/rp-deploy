function Install-RiskPro {
  <#
    .SYNOPSIS
    Install RiskPro

    .DESCRIPTION
    Install OneSumX for Risk Management application

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER WebServers
    The application servers parameter corresponds to the configuration of the application servers.

    .PARAMETER Servers
    The servers parameter corresponds to the configuration of the server grid.

    .PARAMETER Unattended
    The unattended switch specifies if the script should run in non-interactive mode.

    .INPUTS
    None. You cannot pipe objects to Install-RiskPro.

    .OUTPUTS
    None. Install-RiskPro does not return any object.

    .NOTES
    File name:      Install-RiskPro.ps1
    Author:         Florian Carrier
    Creation date:  16/12/2019
    Last modified:  26/02/2020
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
    # Initialize license variable
    $Global:License = $false
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
    # Database system administrator credentials
    $Properties.DBACredentials = Get-ScriptCredentials -UserName $Properties.DatabaseAdminUsername -Password $Properties.DatabaseAdminPassword -EncryptionKey $EncryptionKey -Label "database system administrator" -Unattended:$Unattended
    # RiskPro database user credentials
    $Properties.RPDBCredentials = Get-ScriptCredentials -UserName $Properties.DatabaseUsername -Password $Properties.DatabaseUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro database user" -Unattended:$Unattended
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
    $DatabaseCheck = Test-DatabaseConnection -DatabaseVendor $Properties.DatabaseType -Hostname $Properties.DatabaseHost -PortNumber $Properties.DatabasePort -Instance $Properties.DatabaseInstance -Credentials $Properties.DBACredentials
    if (-Not $DatabaseCheck) {
      Write-Log -Type "ERROR" -Object "Unable to reach database server ($($Properties.DatabaseServerInstance))" -ExitCode 1
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
    # --------------------------------------------------------------------------
    # Setup database
    # --------------------------------------------------------------------------
    if ($SkipDB) {
      Write-Log -Type "WARN" -Object "Skipping database setup"
    } else {
      # Create user and database
      Invoke-SetupDatabase -Properties $Properties
    }
    # Configure grid
    if ($Properties.CustomGridConfiguration -eq $true) {
      # TODO setup grid configuration from grid CSV files
      Write-Log -Type "ERROR" -Object "Custom grid configuration not supported yet"
      Write-Log -Type "WARN"  -Object "Defaulting to standard grid configuration"
    }
    foreach ($Server in $Servers) {
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      Invoke-GridSetup -Properties ($Properties + $WebServer) -Server $Server
    }
    # --------------------------------------------------------------------------
    # Setup servers
    # --------------------------------------------------------------------------
    # Loop through the grid
    foreach ($Server in $Servers) {
      Write-Log -Type "INFO" -Object "Setup $($Server.Hostname) application server"
      # Get server properties
      $WebServer = $WebServers[$Server.Hostname]
      # Encryption key
      $EncryptionKey = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
      # WildFly administration account
      $AdminCredentials = Get-ScriptCredentials -UserName $WebServer.AdminUserName -Password $WebServer.AdminPassword -EncryptionKey $EncryptionKey -Label "$($WebServer.WebServerType) administration user" -Unattended:$Unattended
      # Check application server status
      Write-Log -Type "DEBUG" -Object "Check application server status"
      $Controller = $WebServer.Hostname + ':' + $WebServer.AdminPort
      $Running = Resolve-ServerState -Path $Properties.JBossClient -Controller $Controller -HTTPS:$Properties.EnableHTTPS
      if ($Running -eq $false) {
        Write-Log -Type "WARN" -Object "Web-Server $($Server.Hostname) is not running"
        if ($Attended) {
          $Confirm = Confirm-Prompt -Prompt "Do you want to start the application server?"
        }
        if ($Unattended -Or $Confirm) {
          # Start application server
          Start-WebServer -Properties ($Properties + $WebServer)
          # Wait for server to run
          Wait-WildFly -Path $Properties.JBossClient -Controller $Controller -Credentials $AdminCredentials -TimeOut 300 -RetryInterval 1
        }
      }
      # Configure application server
      Invoke-SetupJBoss -Properties ($Properties + $WebServer) -Server $Server -Credentials $AdminCredentials
    }
    # --------------------------------------------------------------------------
    # Deploy application
    # --------------------------------------------------------------------------
    # Setup security
    # TODO configure shiro.ini
    # Generate web-application
    Invoke-GenerateWebApp -Properties $Properties
    # Deploy web-application
    Invoke-DeployRiskPro -Properties $Properties -WebServers $WebServers -Servers $Servers -Unattended:$Unattended
    # --------------------------------------------------------------------------
    # Setup system model
    # --------------------------------------------------------------------------
    if ($Global:License -eq $true) {
      # Create user group
      Write-Log -Type "INFO" -Object "Creating administration user group"
      $CreateUserGroup = Invoke-CreateUserGroup -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -GroupName $Properties.AdminUserGroup
      Assert-RiskProBatchClientOutcome -Log $CreateUserGroup -Object """$($Properties.AdminUserGroup)"" user group" -Verb "create"
      # Add administration user to administration user group
      Write-Log -Type "INFO" -Object "Adding admin user to administration user group"
      $ModifyUser = Invoke-ModifyUser -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -UserName $RiskProAdminCredentials.UserName -NewUserName $RiskProAdminCredentials.UserName -NewEmployeeName "Administrator" -UserGroups $Properties.AdminUserGroup
      Assert-RiskProBatchClientOutcome -Log $ModifyUser -Object "Administrator user" -Verb "add"
      # Create system model group
      Write-Log -Type "INFO" -Object "Creating model group ""$($Properties.SystemModelGroup)"""
      $CreateModelGroup = Invoke-CreateModelGroup -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelGroup $Properties.SystemModelGroup
      Assert-RiskProBatchClientOutcome -Log $CreateModelGroup -Object """$($Properties.SystemModelGroup)"" model group" -Verb "create"
      # Grant permissions on system model group to administration user group
      Write-Log -Type "INFO" -Object "Granting permissions to administration user group"
      $GrantRole = Grant-Role -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelGroupName $Properties.SystemModelGroup -RoleName "Administrator" -UserGroupName "Administrators"
      Assert-RiskProBatchClientOutcome -Log $GrantRole -Object "Administrator role" -Verb "grant"
      # Create blank system model
      Write-Log -Type "INFO" -Object "Creating $($Properties.SystemModelName) model"
      $CreateModel = Invoke-CreateModel -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelName $Properties.SystemModelName -Type $Properties.SystemModelType -Description $Properties.SystemModelDescription -Currency $Properties.SystemModelCurrency -ModelGroupName $Properties.SystemModelGroup
      Assert-RiskProBatchClientOutcome -Log $CreateModel -Object """$($Properties.SystemModelName)"" model" -Verb "create"
    } else {
      Write-Log -Type "WARN" -Object "Please activate the product license"
    }
    # --------------------------------------------------------------------------
    Write-Log -Type "CHECK" -Object "RiskPro $($Properties.RiskProVersion) has been successfully installed"
  }
}
