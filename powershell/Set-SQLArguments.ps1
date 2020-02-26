function Set-SQLArguments {
  <#
    .SYNOPSIS
    Define arguments for SQL commands

    .DESCRIPTION
    Generate set of arguments for the call to SQL commands using Invoke-SqlCmd (or Invoke-OracleCmd)

    .PARAMETER Properties
    The properties parameter corresponds to the database connection properties.

    It must contains the following attributes for Microsoft SQL Server databases:
    - DatabaseServerInstance: Name of the database server and instance
    - DatabaseName:           Name of the database

    It must contains the following attributes for Oracle databases:
    - DatabaseHost:           Name of the database host
    - DatabasePort:           Port number of the database server
    - DatabaseInstance:       Name of the database service

    Optional attributes:
    - AbortOnError:           Switch to abort command upon error
    - ConnectionTimeOut:      Time in seconds before connection timeout
    - EncryptConnection:      Switch to encrypt the connection
    - IncludeSqlUserErrors:   Switch to include SQL error messages
    - OutputSqlErrors:        Switch to output SQL error messages
    - QueryTimeOut:           Time in seconds before query timeout

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the database user.

    .NOTES
    File name:      Set-SQLArguments.ps1
    Author:         Florian CARRIER
    Creation date:  15/11/2019
    Last modified:  26/02/2020

    .LINK
    Invoke-SQLCommand

    .LINK
    Invoke-OracleCmd
  #>
  [CmdletBinding ()]
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
      Mandatory   = $false,
      HelpMessage = "Database credentials"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Instantiate variable
    $SQLArguments = New-Object -TypeName "System.Collections.Specialized.OrderedDictionary"
    # Optional properties
    $OptionalProperties = @(
      "AbortOnError",
      "ConnectionTimeOut",
      "EncryptConnection",
      "IncludeSqlUserErrors",
      "OutputSqlErrors",
      "QueryTimeOut"
    )
  }
  Process {
    # Connection string
    switch ($Properties.DatabaseType) {
      "Oracle" {
        $SQLArguments.Add("Hostname"          , $Properties.DatabaseHost)
        $SQLArguments.Add("PortNumber"        , $Properties.DatabasePort)
        $SQLArguments.Add("ServiceName"       , $Properties.DatabaseInstance)
      }
      "SQLServer" {
        $SQLArguments.Add("ServerInstance"    , $Properties.DatabaseServerInstance)
        $SQLArguments.Add("Database"          , $Properties.DatabaseName)
      }
    }
    # Credentials
    $SQLArguments.Add("Credential"            , $Credentials)
    # TODO add check for SQL Server module
    # https://stackoverflow.com/a/51623386/6194249
    # https://docs.microsoft.com/en-us/sql/database-engine/invoke-sqlcmd-cmdlet
    # $SQLArguments.Add("Username"            , $Credentials.UserName)
    # $SQLArguments.Add("Password"            , $Credentials.GetNetworkCredential().Password)
    # Generic properties
    foreach ($OptionalProperty in $OptionalProperties) {
      # Check if property is provided
      if ($Properties.$OptionalProperties) {
        # Add property to argument list
        $SQLArguments.Add($OptionalProperties, $Properties.$OptionalProperties)
      }
    }
    # Return SQL arguments
    return $SQLArguments
  }
}
