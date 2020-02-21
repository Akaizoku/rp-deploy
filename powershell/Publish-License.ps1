function Publish-License {
  <#
    .SYNOPSIS
    Setup license file

    .DESCRIPTION
    Setup the license file to embed it in the web-application

    .PARAMETER Path
    The path parameter corresponds to the path to the license file.

    .PARAMETER Target
    The target parameter corresponds to the path to the target location.

    .INPUTS
    None. You cannot pipe objects to Publish-License.

    .OUTPUTS
    None. Publish-License does not return any object.

    .NOTES
    File name:      Publish-License.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  21/02/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Path to the license directory"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Path,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Target destination"
    )]
    [ValidateNotNullOrEmpty ()]
    [Alias ("Destination")]
    [String]
    $Target
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Instantiate variable
    $Skip = $false
  }
  Process {
    # Setup license
    Write-Log -Type "INFO" -Object "Setup license file"
    if (Test-Object -Path $Path) {
      $License = Get-ChildItem -Path $Path -Filter "*.jar"
      if ($License.Count -eq 0) {
        Write-Log -Type "WARN" -Object "No license file was found"
        $Skip = $true
      } elseif ($License.Count -gt 1) {
        Write-Log -Type "ERROR" -Object "More than one license file were found"
        $Skip = $true
      } elseif ($License.Count -eq 1) {
        # Check that target directory exists
        if (Test-Object -Path $Target -NotFound) {
          Write-Log -Type "DEBUG" -Object "Create path $($Target)"
          New-Item -ItemType "Directory" -Path $Target | Out-Null
        }
        # Copy license file
        Write-Log -Type "DEBUG" -Object $License.Name
        Copy-Item -Path $License.FullName -Destination $Target -Force
        $Global:License = $true
      }
    } else {
      Write-Log -Type "ERROR"  -Object "Path not found $Path"
      $Skip = $true
    }
    if ($Skip) {
      Write-Log -Type "WARN" -Object "Skipping license setup"
      $Global:License = $false
    }
  }
}
