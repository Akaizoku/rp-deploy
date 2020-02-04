# ------------------------------------------------------------------------------
# Setup grid database configuration
# ------------------------------------------------------------------------------
function Invoke-GridSetup {
  [CmdletBinding ()]
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
    # SQL commands arguments
    $SQLArguments = Set-SQLArguments -Properties $Properties
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
