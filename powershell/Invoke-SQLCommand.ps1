function Invoke-SQLCommand {
  <#
    .SYNOPSIS
    Invoke SQL command

    .DESCRIPTION
    Run a SQL command

    .NOTES
    File name:      Invoke-SQLCommand.ps1
    Author:         Florian Carrier
    Creation date:  06/02/2020
    Last modified:  11/02/2020
    Dependencies:   - Invoke-SqlCmd requires the SQLServer PowerShell module
                    - Invoke-OracleCmd requires Oracle Data Provider for .NET

    .LINK
    https://www.powershellgallery.com/packages/PSTK

    .LINK
    Invoke-SqlCmd

    .LINK
    Invoke-OracleCmd

    .LINK
    https://www.oracle.com/database/technologies/appdev/dotnet/odp.html

    .LINK
    https://www.nuget.org/packages/Oracle.ManagedDataAccess.Core
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position          = 1,
      Mandatory         = $true,
      HelpMessage       = "Name of the database host",
      ParameterSetName  = "Oracle"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $Hostname,
    [Parameter (
      Position          = 2,
      Mandatory         = $true,
      HelpMessage       = "Database server port number",
      ParameterSetName  = "Oracle"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $PortNumber,
    [Parameter (
      Position          = 3,
      Mandatory         = $true,
      HelpMessage       = "Name of the Oracle service",
      ParameterSetName  = "Oracle"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $ServiceName,
    [Parameter (
      Position          = 1,
      Mandatory         = $true,
      HelpMessage       = "Name of the database host and instance",
      ParameterSetName  = "SQLServer"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $ServerInstance,
    [Parameter (
      Position          = 2,
      Mandatory         = $true,
      HelpMessage       = "Name of the database",
      ParameterSetName  = "SQLServer"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $Database,
    [Parameter (
      Position    = 4,
      Mandatory   = $true,
      HelpMessage = "SQL query"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $Query,
    [Parameter (
      Position          = 5,
      Mandatory         = $false,
      HelpMessage       = "Database user credentials"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      Position          = 5,
      Mandatory         = $false,
      HelpMessage       = "User name"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.String]
    $Username,
    [Parameter (
      Position          = 6,
      Mandatory         = $false,
      HelpMessage       = "Password"
    )]
    # [ValidateNotNullOrEmpty ()]
    [System.String]
    $Password,
    [Parameter (
      Mandatory   = $false,
      HelpMessage = "Connection timeout (in seconds)"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Int32]
    $ConnectionTimeOut = 3,
    [Parameter (
      Mandatory   = $false,
      HelpMessage = "Query timeout (in seconds)"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Int32]
    $QueryTimeOut = 300,
    [Parameter (
      HelpMessage = "Abort on error"
    )]
    [Switch]
    $AbortOnError,
    [Parameter (
      HelpMessage = "Encrypt connection"
    )]
    [Switch]
    $EncryptConnection,
    [Parameter (
      HelpMessage = "Include SQL user errors"
    )]
    [Switch]
    $IncludeSqlUserErrors,
    [Parameter (
      HelpMessage = "Out SQL errors"
    )]
    [Switch]
    $OutputSqlErrors
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Cast output SQL error as boolean for Invoke-SqlCmd
    if ($OutputSqlErrors) {
      $OutputErrors = $true
    } else {
      $OutputErrors = $false
    }
  }
  Process {
    switch ($PSCmdlet.ParameterSetName) {
      "Oracle" {
        # Use custom Oracle SQL command function
        if ($PSBoundParameters.ContainsKey("Credentials")) {
          # Use credentials
          Invoke-OracleCmd -Hostname $Hostname -PortNumber $PortNumber -ServiceName $ServiceName -Query $Query -Credentials $Credentials -ConnectionTimeOut $ConnectionTimeOut -QueryTimeOut $QueryTimeOut -AbortOnError:$AbortOnError -EncryptConnection:$EncryptConnection -IncludeSqlUserErrors:$IncludeSqlUserErrors -OutputSqlErrors:$OutputSqlErrors
        } elseif ($PSBoundParameters.ContainsKey("Username") -And $PSBoundParameters.ContainsKey("Password")) {
          # Use provided plain-text username and password
          Invoke-OracleCmd -Hostname $Hostname -PortNumber $PortNumber -ServiceName $ServiceName -Query $Query -Username $Username -Password $Password -ConnectionTimeOut $ConnectionTimeOut -QueryTimeOut $QueryTimeOut -AbortOnError:$AbortOnError -EncryptConnection:$EncryptConnection -IncludeSqlUserErrors:$IncludeSqlUserErrors -OutputSqlErrors:$OutputSqlErrors
        } else {
          # Assume integrated security
          Invoke-OracleCmd -Hostname $Hostname -PortNumber $PortNumber -ServiceName $ServiceName -Query $Query -ConnectionTimeOut $ConnectionTimeOut -QueryTimeOut $QueryTimeOut -AbortOnError:$AbortOnError -EncryptConnection:$EncryptConnection -IncludeSqlUserErrors:$IncludeSqlUserErrors -OutputSqlErrors:$OutputSqlErrors
        }
      }
      "SQLServer" {
        # Use standard SQL Server command function
        if ($PSBoundParameters.ContainsKey("Credentials")) {
          # Use credentials
          Invoke-SqlCmd -ServerInstance $ServerInstance -Database $Database -Query $Query -Credential $Credentials -ConnectionTimeOut $ConnectionTimeOut -QueryTimeOut $QueryTimeOut -AbortOnError:$AbortOnError -EncryptConnection:$EncryptConnection -IncludeSqlUserErrors:$IncludeSqlUserErrors -OutputSqlErrors $OutputErrors
        } elseif ($PSBoundParameters.ContainsKey("Username") -And $PSBoundParameters.ContainsKey("Password")) {
          # Use provided plain-text username and password
          Invoke-SqlCmd -ServerInstance $ServerInstance -Database $Database -Query $Query -Username $Username -Password $Password -ConnectionTimeOut $ConnectionTimeOut -QueryTimeOut $QueryTimeOut -AbortOnError:$AbortOnError -EncryptConnection:$EncryptConnection -IncludeSqlUserErrors:$IncludeSqlUserErrors -OutputSqlErrors $OutputErrors
        } else {
          # Assume integrated security
          Invoke-SqlCmd -ServerInstance $ServerInstance -Database $Database -Query $Query -ConnectionTimeOut $ConnectionTimeOut -QueryTimeOut $QueryTimeOut -AbortOnError:$AbortOnError -EncryptConnection:$EncryptConnection -IncludeSqlUserErrors:$IncludeSqlUserErrors -OutputSqlErrors $OutputErrors
        }
      }
      default {
        Write-Log -Type "ERROR" -Object "Invalid parameter set $($PSCmdlet.ParameterSetName)" -ExitCode 1
      }
    }
  }
}
