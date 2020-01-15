# ------------------------------------------------------------------------------
# Generate web-application
# ------------------------------------------------------------------------------
function Invoke-GenerateWebApp {
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    # Clean-up existing libraries to avoid conflict
    Write-Log -Type "DEBUG" -Object $Properties.RPLibDirectory
    if (Test-Object -Path $Properties.RPLibDirectory) {
      Write-Log -Type "INFO" -Object "Clean-up libraries directory"
      Remove-Item -Path $Properties.RPLibDirectory -Recurse -Force
    }
    # Create library directory
    if (Test-Object -Path $Properties.RPJARPatchDirectory -NotFound) {
      Write-Log -Type "DEBUG" -Object "Create path $($Properties.RPJARPatchDirectory)"
      New-Item -ItemType "Directory" -Path $Properties.RPJARPatchDirectory | Out-Null
    } else {
      Write-Log -Type "DEBUG" -Object "Path already exists $($Properties.RPJARPatchDirectory)"
    }
    # Setup license
    Publish-License -Path $Properties.LicenseDirectory -Target $Properties.RPJARPatchDirectory
    # Setup patches
    Publish-Patch -Path $Properties.PatchDirectory -JARTarget $Properties.RPJARPatchDirectory -ZipTarget $Properties.RPZIPPatchDirectory
    # Generate web-application
    Write-Log -Type "INFO" -Object "Generate $($Properties.RPWebApplication) web-application"
    $JavaProperties = Get-JavaProperties -Properties $Properties -Type "WebApp"
    $Log = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.RunXMLFile -Operation "generateDefaultWebApp" -Properties $JavaProperties
    Assert-RiskProANTOutcome -Log $Log -Object "$($Properties.RPWebApplication) WAR file" -Verb "generate"
  }
}
