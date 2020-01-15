function Wait-WildFly {
  <#
    .SYNOPSIS
    Wait JBoss server

    .DESCRIPTION
    Wait until a JBoss instance is running

    .PARAMETER Path
    The optional path parameter corresponds to the path to the JBoss batch client.

    .PARAMETER Controller
    The controller parameter corresponds to the host to connect to.

    .PARAMETER Credentials
    The optional credentials parameter correspond to the credentials of the account to use to connect to the JBoss instance.

    .PARAMETER TimeOut
    The optional time-out parameter corresponds to the wait period after which the server is declared unreachable.

    .PARAMETER RetryInterval
    The optional retry interval parameter is the interval in millisecond in between each queries to check the server state.

    .NOTES
    File name:     Wait-WildFly.ps1
    Author:        Florian Carrier
    Creation date: 20/12/2019
    Last modified: 13/01/2020
  #>
  Param(
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Path to the JBoss client"
    )]
    [ValidateNotNUllOrEmpty ()]
    [String]
    $Path,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Controller"
    )]
    # TODO validate format
    [ValidateNotNUllOrEmpty ()]
    [String]
    $Controller,
    [Parameter (
      Position    = 3,
      Mandatory   = $false,
      HelpMessage = "User credentials"
    )]
    [ValidateNotNUllOrEmpty ()]
    [System.Management.Automation.PSCredential]
    $Credentials,
    [Parameter (
      Position    = 4,
      Mandatory   = $false,
      HelpMessage = "Time in seconds before time-out"
    )]
    [ValidateNotNullOrEmpty ()]
    [Int]
    $TimeOut = 60,
    [Parameter (
      Position    = 5,
      Mandatory   = $false,
      HelpMessage = "Interval in between retries"
    )]
    [ValidateNotNullOrEmpty ()]
    [Int]
    $RetryInterval = 1
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    # Initiate timer
    $Timer = [System.Diagnostics.Stopwatch]::StartNew()
    # Wait until server is running or timeout is reached
    while ($Timer.Elapsed.TotalSeconds -lt $TimeOut) {
      # Check server state
      if ($PSBoundParameters.ContainsKey("Credentials")) {
        $Running = Test-ServerState -Path $Path -Controller $Controller -Credentials $Credentials -State "running"
      } else {
        $Running = Test-ServerState -Path $Path -Controller $Controller -State "running"
      }
      if ($Running) {
        # If server is running
        break
      } else {
        Start-Sleep -Seconds $RetryInterval
      }
    }
    # Stop timer
    $Timer.Stop()
    # Check timer
    if (($Timer.Elapsed.TotalSeconds -gt $TimeOut) -And (-Not $Running)) {
      # Timeout
      return $false
    } else {
      return $true
    }
  }
}
