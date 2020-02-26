function Get-ConnectionString {
  <#
    .SYNOPSIS
    Build database connection string

    .DESCRIPTION
    Build a connection string according to provided database properties

    .NOTES
    File name:      Backup-Schema.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  21/01/2020
    WARNING:        This has not been tested for Oracle
  #>
  [CmdletBinding(
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Database type"
    )]
    [ValidateSet (
      "Oracle",
      "SQLServer"
    )]
    [String]
    $Type,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Database host name"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Hostname,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Database port number"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $PortNumber,
    [Parameter (
      Position    = 3,
      Mandatory   = $false,
      HelpMessage = "Database instance name"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Instance,
    [Parameter (
      Position    = 4,
      Mandatory   = $false,
      HelpMessage = "Database name"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Database,
    [Parameter (
      Position    = 5,
      Mandatory   = $true,
      HelpMessage = "Connector type"
    )]
    [ValidateSet (
      "JDBC",
      "ODBC"
    )]
    [String]
    $Connector
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    switch ($Connector) {
      "JDBC" {
        switch ($Type) {
          "SQLServer" {
            # Build connection string
            $ConnectionString = "jdbc:sqlserver://;serverName=$Hostname;portNumber=$PortNumber"
            # Add database instance
            if ($Instance) {
              $ConnectionString = $ConnectionString + ";instanceName=$Instance"
            }
            # Add database name
            if ($Database) {
              $ConnectionString = $ConnectionString + ";databaseName=$Database"
            }
          }
          "Oracle" {
            # WARNING use EZ syntax to prevent parsing issues with JBoss batch client
            if ($Instance) {
              $ConnectionString =
              "jdbc:oracle:thin:@//$($Hostname):$PortNumber/$Instance"
            } else {
              $ConnectionString = "jdbc:oracle:thin:@//$($Hostname):$PortNumber"
            }
          }
        }
      }
      default {
        Write-Log -Type "ERROR" -Message "$Connector connector not implemented yet" -ExitCode 1
      }
    }
    # Return connection string
    return $ConnectionString
  }
}
