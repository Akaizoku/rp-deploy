function Set-SQLArguments {
  <#
    .SYNOPSIS
    Define arguments for SQL commands

    .DESCRIPTION
    Generate set of arguments for the call to SQL commands using Invoke-SqlCmd

    .PARAMETER Properties
    The properties parameter corresponds to the database properties. It must contains the following attributes:
    - DatabaseServerInstance: Name of the database server and instance
    - DatabaseName: Name of the database
    - AbortOnError: Switch to abort command upon error
    - ConnectionTimeOut: Time in seconds before connection timeout
    - EncryptConnection: Switch to encrypt the connection
    - IncludeSqlUserErrors: Switch to include SQL error messages
    - OutputSqlErrors: Switch to output SQL error messages
    - QueryTimeOut: Time in seconds before query timeout

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the database user to be used.

    .NOTES
    File name:      Set-SQLArguments.ps1
    Author:         Florian CARRIER
    Creation date:  15/11/2019
    Last modified:  20/10/2019
    Dependencies:   SQL Server PowerShell Module (SQLServer or SQLPS)
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
  }
  Process {
    # Connection string
    $SQLArguments.Add("ServerInstance"        , $Properties.DatabaseServerInstance)
    $SQLArguments.Add("Database"              , $Properties.DatabaseName)
    # Credentials
    $SQLArguments.Add("Credential"            , $Credentials)
    # TODO add check for SQL Server module
    # https://stackoverflow.com/a/51623386/6194249
    # https://docs.microsoft.com/en-us/sql/database-engine/invoke-sqlcmd-cmdlet
    # $SQLArguments.Add("Username"            , $Credentials.UserName)
    # $SQLArguments.Add("Password"            , $Credentials.GetNetworkCredential().Password)
    # Generic properties
    $SQLArguments.Add("AbortOnError"          , $Properties.AbortOnError)
    $SQLArguments.Add("ConnectionTimeOut"     , $Properties.ConnectionTimeOut)
    $SQLArguments.Add("EncryptConnection"     , $Properties.EncryptConnection)
    $SQLArguments.Add("IncludeSqlUserErrors"  , $Properties.IncludeSqlUserErrors)
    $SQLArguments.Add("OutputSqlErrors"       , $Properties.OutputSqlErrors)
    $SQLArguments.Add("QueryTimeOut"          , $Properties.QueryTimeOut)
    # Return SQL arguments
    return $SQLArguments
  }
}
