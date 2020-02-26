function Invoke-GridSetup {
  <#
    .SYNOPSIS
    Setup RiskPro grid

    .DESCRIPTION
    Set RiskPro grid database configuration

    .NOTES
    File name:      Invoke-GridSetup.ps1
    Author:         Florian CARRIER
    Creation date:  15/10/2019
    Last modified:  26/02/2020
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
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Server properties"
    )]
    [ValidateNotNullOrEmpty ()]
    # [System.Collections.Specialized.OrderedDictionary]
    $Server
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    # --------------------------------------------------------------------------
    # Calculation configuration
    Set-CalculationConfiguration -Properties $Properties
    # --------------------------------------------------------------------------
    # Environment configuration
    Set-EnvironmentConfiguration -Properties $Properties
    # --------------------------------------------------------------------------
    # Job controller configuration
    if ($Server."Job Controller" -eq "TRUE") {
      Set-JobController -Properties $Properties
    }
    # --------------------------------------------------------------------------
    # Staging area configuration
    if ($Server."Staging Area" -eq "TRUE") {
      Set-StagingArea -Properties $Properties
      Set-OLAPCube    -Properties $Properties
    }
    # --------------------------------------------------------------------------
    # TESS configuration
    if ($Server."TESS" -eq "TRUE") {
      Set-TESS -Properties $Properties
    }
    # --------------------------------------------------------------------------
    # Calculator configuration
    if ($Server."Calculator" -eq "TRUE") {
      Set-Calculator -Properties $Properties
    }
  }
}
