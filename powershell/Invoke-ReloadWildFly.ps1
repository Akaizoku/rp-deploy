function Invoke-ReloadWildFly {
  <#
    .SYNOPSIS
    Reload WildFly

    .DESCRIPTION
    Wrapper function to reload WildFly with error handling

    .PARAMETER Path
    The path parameter corresponds to the path to the JBoss client.

    .PARAMETER Controller
    The controller parameter corresponds to the controller of the WildFly instance.

    .PARAMETER Credentials
    The credentials parameter corresponds to the credentials of the WildFly instance administration account.

    .PARAMETER RetryCount
    The optional retry count parameter corresponds to the number of retries to perform before failing. The default value is three.

    .PARAMETER Quiet
    The remove switch defines if the custom configuration should be removed from the WildFly instance.

    .INPUTS
    None. You cannot pipe objects to Invoke-ReloadWildFly.

    .OUTPUTS
    None. Invoke-ReloadWildFly does not return any object.

    .NOTES
    File name:      Invoke-ReloadWildFly.ps1
    Author:         Florian Carrier
    Creation date:  15/01/2020
    Last modified:  15/01/2020
  #>
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Path to the JBoss client"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Path,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Controller"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Controller,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "User credentials"
    )]
    [ValidateNotNUllOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      Position    = 4,
      Mandatory   = $false,
      HelpMessage = "Number of retries"
    )]
    [ValidateNotNUllOrEmpty ()]
    [Int]
    $RetryCount = 3,
    [Parameter (
      HelpMessage = "Quiet switch"
    )]
    [Switch]
    $Quiet
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Output mode
    if ($Quiet) {
      $OutputMode = "DEBUG"
    } else {
      $OutputMode = "INFO"
    }
  }
  Process {
    Write-Log -Type $OutputMode -Object "Reload WildFly"
    for ($i=0; $i -le $RetryCount; $i++) {
      # Reload server
      $Reload = Invoke-ReloadServer -Path $Path -Controller $Controller -Credentials $Credentials
      # Check outcome
      if (-Not (Test-JBossClientOutcome -Log $Reload)) {
        # Check if java.util.concurrent.CancellationException
        if (Select-String -InputObject $Reload -Pattern "java.util.concurrent.CancellationException" -SimpleMatch -Quiet) {
          # Wait and try again
          Start-Sleep -Seconds 1
        } else {
          Write-Log -Type "WARN"  -Object "WildFly could not be reloaded"
          Write-Log -Type "ERROR" -Object $Reload -ExitCode 1
        }
      } else {
        # Wait for web-server to come back up
        $Running = Wait-WildFly -Path $Path -Controller $Controller -Credentials $Credentials -TimeOut 300 -RetryInterval 1
        if (-Not $Running) {
          Write-Log -Type "ERROR" -Object "Timeout. WildFly failed to come back up" -ExitCode 1
        }
        break
      }
    }
  }
}
