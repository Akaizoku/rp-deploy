function Get-JavaProperties {
  <#
    .SYNOPSIS
    Generate Java property string

    .DESCRIPTION
    Parse and generate string of Java properties

    .PARAMETER Properties
    The properties parameter corresponds to the system properties to parse.

    .PARAMETER Type
    The type parameter corresponds to the type of properties to extract from the provided properties.

    .INPUTS
    None. You cannot pipe items to Get-JavaProperties.

    .OUTPUTS
    Get-JavaProperties returns a string containing the formatted requested Java properties.

    .EXAMPLE
    $JBossProperties = [Ordered]@{
      AdminPort         = 9990
      DatabaseDriver    = "mssql"
      DatabaseURL       = "localhost"
      Hostname          = "localhost"
      HTTPPort          = 8080
      RPDBCredentials   = (Get-Credential -Message "RiskPro database credentials")
      RPWebApplication  = "riskpro-web"
    }
    Get-JavaProperties -Properties $JBossProperties -Type "JBoss"

    In this example, the function will generate a string containing the required Java properties for a JBoss web-server.

    .EXAMPLE
    $JBossProperties = [Ordered]@{
      AdminPort         = 9990
      DatabaseDriver    = "mssql"
      DatabaseURL       = "localhost"
      Hostname          = "localhost"
      HTTPPort          = 8080
      RPDBCredentials   = (Get-Credential -Message "RiskPro database credentials")
      RPWebApplication  = "riskpro-web"
    }
    Get-JavaProperties -Properties $JBossProperties -Type "JBoss"

    In this example, the function will generate a string containing the required Java properties for a JBoss web-server.

    .NOTES
    File name:      Get-JavaProperties.ps1
    Author:         Florian CARRIER
    Creation date:  15/10/2019
    Last modified:  03/02/2020
  #>
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Properties"
    )]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Type of properties"
    )]
    [ValidateSet ("JBoss", "Database", "WebApp")]
    [String]
    $Type
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Prepare container for Java properties
    $JavaProperties = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
  }
  Process {
    switch ($Type) {
      "JBoss" {
        # Properties for JBoss setup
        $JavaProperties = [Ordered]@{
          "db.driver.name"              = $Properties.DatabaseDriver
          "db.password"                 = $Properties.RPDBCredentials.GetNetworkCredential().Password
          "db.url"                      = $Properties.DatabaseURL
          "db.user"                     = $Properties.RPDBCredentials.UserName
          "jboss.host"                  = $Properties.Hostname
          "jboss.port.admin"            = $Properties.AdminPort
          "jboss.port.http"             = $Properties.HTTPPort
          "webapp.name"                 = $Properties.RPWebApplication
        } | ConvertTo-JavaProperty
      }
      "Database" {
        # Microsoft SQL Server database properties
        if ($Properties.DatabaseType -eq "SQLServer") {
          # Build host address
          if ($Properties.DatabaseInstance) {
            $SQLServerHost = $Properties.DatabaseHost + "\\" + $Properties.DatabaseInstance
          } else {
            $SQLServerHost = $Properties.DatabaseHost
          }
          # Select required properties
          $JavaProperties = [Ordered]@{
            "sqlserver.cmdline"         = $Properties.CommandLine
            "sqlserver.collation"       = $Properties.DatabaseCollation
            "sqlserver.db"              = $Properties.DatabaseName
            "sqlserver.host"            = $SQLServerHost
            "sqlserver.password"        = $Properties.RPDBCredentials.GetNetworkCredential().Password
            "sqlserver.port"            = $Properties.DatabasePort
            "sqlserver.schema"          = $Properties.DatabaseSchema
            "sqlserver.system.password" = $Properties.DBACredentials.GetNetworkCredential().Password
            "sqlserver.system.user"     = $Properties.DBACredentials.UserName
            "sqlserver.user"            = $Properties.RPDBCredentials.UserName
          } | ConvertTo-JavaProperty
        }
        # Oracle database properties
        elseif ($Properties.DatabaseType -eq "Oracle") {
          # User table space
          if ($Database.UserTableSpace) {
            $UserTableSpace = $Database.UserTableSpace
          } else {
            $UserTableSpace = "USERS"
          }
          # Select required properties
          $JavaProperties = [Ordered]@{
            "ora.cmdline"               = $Properties.CommandLine
            "ora.db"                    = "//$($Properties.DatabaseHost):$($Properties.DatabasePort)/$($Properties.DatabaseInstance)"
            "ora.host"                  = $Properties.DatabaseHost
            "ora.password"              = $Properties.RPDBCredentials.GetNetworkCredential().Password
            "ora.port"                  = $Properties.DatabasePort
            "ora.service"               = $Properties.DatabaseInstance
            "ora.system.password"       = $Properties.DBACredentials.GetNetworkCredential().Password
            "ora.system.user"           = $Properties.DBACredentials.UserName
            "ora.user"                  = $Properties.RPDBCredentials.UserName
            "ora.usertablespace"        = $UserTableSpace
          } | ConvertTo-JavaProperty
        } else {
          Write-Log -Type "ERROR" -Object "$($Properties.DatabaseType) database is not supported" -ErrorCode 1
        }
      }
      "WebApp" {
        # RiskPro web-application properties
        $JavaProperties = [Ordered]@{
          "jboss.host"                  = $Properties.Hostname
          "jboss.port.admin"            = $Properties.AdminPort
          "jboss.port.http"             = $Properties.HTTPPort
          "webapp.name"                 = $Properties.RPWebApplication
        } | ConvertTo-JavaProperty
      }
      "default" {
        Write-Log -Type "ERROR" -Object "$Type type is not supported" -ErrorCode 1
      }
    }
    # Return Java properties
    return $JavaProperties
  }
}
