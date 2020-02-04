# ------------------------------------------------------------------------------
# Setup patches
# ------------------------------------------------------------------------------
function Publish-Patch {
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Path to the patch directory"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $Path,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Target destination for JAR files"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $JARTarget,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Target destination for ZIP files"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $ZIPTarget
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Instantiate variable
    $SkipPatch = $false
  }
  Process {
    Write-Log -Type "INFO" -Object "Setup patches"
    if (Test-Object -Path $Path) {
      # JAR patches
      $JARPatches = Get-ChildItem -Path $Path -Filter "*.jar"
      if ($JARPatches.Count -eq 0) {
        Write-Log -Type "DEBUG" -Object "No JAR patch was found"
      } else {
        # Check that target directory exists
        if (Test-Object -Path $JARTarget -NotFound) {
          Write-Log -Type "DEBUG" -Object "Create path $($JARTarget)"
          New-Item -ItemType "Directory" -Path $JARTarget | Out-Null
        }
        # Copy JAR files
        foreach ($JARPatch in $JARPatches) {
          Write-Log -Type "INFO" -Object "Setup $($JARPatch.BaseName)"
          Copy-Item -Path $JARPatch.FullName -Destination $JARTarget -Force
        }
      }
      # ZIP patches
      $ZIPPatches = Get-ChildItem -Path $Path -Filter "*.zip"
      if ($ZIPPatches.Count -eq 0) {
        Write-Log -Type "DEBUG" -Object "No ZIP patch was found"
      } else {
        # Check that target directory exists
        if (Test-Object -Path $ZIPTarget -NotFound) {
          Write-Log -Type "DEBUG" -Object "Create path $($JARTarget)"
          New-Item -ItemType "Directory" -Path $ZIPTarget | Out-Null
        }
        # Copy ZIP files
        foreach ($ZIPPatch in $ZIPPatches) {
          Write-Log -Type "INFO" -Object "Setup $($ZIPPatch.BaseName)"
          Copy-Item -Path $ZIPPatch.FullName -Destination $ZIPPatchDestination -Force
        }
      }
    } else {
      Write-Log -Type "ERROR" -Object "Path not found $($Path)"
      # TODO add checkpoint
      Write-Log -Type "INFO"  -Object "Skipping patch setup"
    }
  }
}
