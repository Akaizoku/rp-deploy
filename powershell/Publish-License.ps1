# ------------------------------------------------------------------------------
# Setup license file
# ------------------------------------------------------------------------------
function Publish-License {
  [CmdletBinding ()]
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
        Write-Log -Type "WARN" -Object "Skipping license setup"
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
      }
    } else {
      Write-Log -Type "ERROR"  -Object "Path not found $Path"
      $Skip = $true
    }
    if ($Skip) {
      Write-Log -Type "INFO"  -Object "Skipping license setup"
    }
  }
}
