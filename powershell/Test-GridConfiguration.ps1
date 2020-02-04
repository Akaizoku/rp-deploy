function Test-GridConfiguration {
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
      Mandatory   = $true,
      HelpMessage = "Server properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Check grid configuration
    $GridCheck = [Ordered]@{
      "TESS"            = 0
      "Job Controller"  = 0
      "Staging Area"    = 0
      "Calculator"      = 0
    }
    # Service list
    $Services = New-Object "System.Collections.ArrayList"
    # Check variables
    $CheckHosts     = $true
    $CheckServices  = $true
    $CheckServer    = $true
  }
  Process {
    # Loop through each server in the grid
    foreach($Server in $Grid) {
      $EnabledServices = 0
      # Check server properties
      if (-Not $Properties[$Server.Hostname]) {
        Write-Log -Type "ERROR" -Object "$($Server.Hostname) server configuration not found"
        $CheckHosts = $false
      }
      # Get list of services
      foreach ($Service in $GridCheck.GetEnumerator()) {
        [Void]$Services.Add($Service.Key)
      }
      # Loop through services
      foreach ($Service in $Services) {
        if ($Server.$Service -eq "TRUE") {
          # Count services
          $EnabledServices    = $EnabledServices    + 1
          $GridCheck.$Service = $GridCheck.$Service + 1
        }
      }
      # Check server configuration
      if ($EnabledServices -lt 1) {
        Write-Log -Type "ERROR" -Object "No services are enabled on $($Server.Hostname) server"
        $CheckServer = $false
      }
    }
    # Check that all services have been configured (at least once)
    foreach ($Service in $GridCheck.GetEnumerator()) {
      if ($Service.Value -lt 1) {
        Write-Log -Type "ERROR" -Object "$($Service.Key) has not been configured"
        $CheckServices = $false
      }
    }
    # Verify configuration
    if (($CheckHosts -eq $false) -Or ($CheckServices -eq $false) -Or ($CheckServer -eq $false)) {
      return $false
    } else {
      return $true
    }
  }
}
