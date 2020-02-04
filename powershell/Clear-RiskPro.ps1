function Clear-RiskPro {
  <#
    .SYNOPSIS
    Clear RiskPro

    .DESCRIPTION
    Clear OneSumX for Risk Management application files

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the application.

    .PARAMETER Unattended
    The unattended switch specifies if the script should run in non-interactive mode.

    .NOTES
    File name:      Clear-RiskPro.ps1
    Author:         Florian Carrier
    Creation date:  03/22/2020
    Last modified:  03/02/2020
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
    Write-Log -Type "INFO" -Object "Cleaning-up RiskPro version $($Properties.RiskProVersion)"
    # --------------------------------------------------------------------------
    # Preliminary checks
    # --------------------------------------------------------------------------
    # Check that RiskPro is installed
    Write-Log -Type "INFO" -Object "Checking installation path"
    if (-Not (Test-Object -Path $Properties.RPHomeDirectory)) {
      Write-Log -Type "ERROR" -Object "Installation path not found $($Properties.RPHomeDirectory)" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Remove installation files
    # --------------------------------------------------------------------------
    # Remove applications
    Write-Log -Type "INFO" -Object "Removing RiskPro files"
    Remove-Item -Path $Properties.RPHomeDirectory -Recurse -Force -Confirm:$Attended
    if (Test-Object -Path $Properties.RPHomeDirectory) {
      Write-Log -Type "ERROR" -Object "An error occured while attempting removing the files" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Clean-up
    # --------------------------------------------------------------------------
    # TODO remove custom paths
    # TODO remove tmp directory
    # Remove environment variables
    if ($Properties.EnableEnvironmentVariable) {
      Write-Log -Type "INFO" -Object "Removing $($Properties.RiskProHomeVariable) environment variable"
      if (Test-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope) {
        if ($RPHome -eq $Properties.RPHomeDirectory) {
          Remove-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
        } else {
          Write-Log -Type "WARN" -Object "$($Properties.RiskProHomeVariable) environment variable points to a different location"
          $Continue = Confirm-Prompt -Prompt "Do you want to remove it?"
          if ($Unattended -Or $Continue) {
            Remove-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
          }
        }
      }
    }
    Write-Log -Type "CHECK" -Object "RiskPro has been successfully cleaned-up"
  }
}
