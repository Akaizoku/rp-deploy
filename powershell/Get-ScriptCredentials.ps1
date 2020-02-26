function Get-ScriptCredentials {
  <#
    .SYNOPSIS
    Get script credentials

    .DESCRIPTION
    Retrieve or prompt user for credentials

    .NOTES
    File name:      Get-ScriptCredentials.ps1
    Author:         Florian CARRIER
    Creation date:  16/12/2019
    Last modified:  17/02/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "User name"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $UserName,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Plain-text representation of encrypted password"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Password,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Encryption key"
    )]
    [ValidateNotNullOrEmpty ()]
    [Byte[]]
    $EncryptionKey,
    [Parameter (
      Position    = 4,
      Mandatory   = $true,
      HelpMessage = "Label of the credentials"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Label,
    [Parameter (
      HelpMessage = "Non-interactive mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    if ($Unattended) {
      # Use provided credentials for database administrator user
      Write-Log -Type "DEBUG" -Object "Use $Label credentials from configuration file"
      try {
        $Credentials = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList ($UserName, (ConvertTo-SecureString -String $Password -Key $EncryptionKey))
      } catch {
        Write-Log -Type "ERROR" -Object "The provided password for $Label could not be decrypted. Please ensure the encryption key is used for the encryption." -ExitCode 1
      }
    } else {
      # Prompt user for credentials
      Write-Log -Type "DEBUG" -Object "Prompt user for $Label credentials"
      $Credentials  = Get-Credential -Message "Please enter the credentials for $Label"
    }
    return $Credentials
  }
}
