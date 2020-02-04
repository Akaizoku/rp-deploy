function Get-MainApplicationServer {
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Grid properties"
    )]
    [ValidateNotNullOrEmpty ()]
    # [System.Collections.Specialized.OrderedDictionary]
    $Grid,
    [Parameter (
      Position    = 2,
      Mandatory   = $false,
      HelpMessage = "Decision criteria"
    )]
    [ValidateSet (
      "TESS",
      "Job Controller",
      "Staging Area",
      "Calculator"
      )]
    [String]
    $Criteria
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    if ($PSBoundParameters.ContainsKey("Criteria")) {
      foreach ($Server in $Grid) {
        if ($Server.$Criteria -eq "TRUE") {
          # Select first server hosting specified service
          $MainApplicationServer = $Server.Hostname
        }
      }
    } else {
      # If no decision criteria is defined, select first server
      $MainApplicationServer = ($Grid | Select-Object -First 1).Hostname
    }
    return $MainApplicationServer
  }
}
