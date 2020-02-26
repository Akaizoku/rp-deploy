function Invoke-GenerateWebApp {
  <#
    .SYNOPSIS
    Generate web-application

    .DESCRIPTION
    Generate RiskPro application WAR file

    .NOTES
    File name:      Invoke-GenerateWebApp.ps1
    Author:         Florian CARRIER
    Creation date:  15/10/2019
    Last modified:  06/02/2020
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
    Write-Log -Type "INFO" -Object "Generate $($Properties.RPWebApplication) application"
    $JavaProperties = Get-JavaProperties -Properties $Properties -Type "WebApp"
    $Log = Invoke-RiskProANTClient -Path $Properties.RPBatchClient -XML $Properties.RunXMLFile -Operation "generateDefaultWebApp" -Properties $JavaProperties
    Assert-RiskProANTOutcome -Log $Log -Object "$($Properties.RPWebApplication) WAR file" -Verb "generate"
  }
}
