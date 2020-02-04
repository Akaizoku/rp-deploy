function Set-GridProperties {
  <#
    .SYNOPSIS
    Set grid properties

    .DESCRIPTION
    Defines grid properties for an instance of OneSumX for Risk Management

    .NOTES
    File name:      Set-GridProperties.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  17/01/2020
  #>
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
  }
  Process {
    # Load template user grid configuration file
    $GridProperties = Get-Properties -File $Properties.UserGridProperties -Directory $Properties.TemplateDirectory
    # Update grid configuration
    $GridProperties.'app.configuration' = 'Configuration'
    $GridProperties.'app.calculator'    = $Server.'Calculator'
    $GridProperties.'app.jobcontroller' = $Server.'Job Controller'
    $GridProperties.'app.stagingarea'   = $Server.'Staging Area'
    $GridProperties.'app.tess'          = $Server.'Tess'
    Write-Log -Type "DEBUG" -Object $GridProperties
    # Save grid configuration
    $UserGridPath = Join-Path -Path $Properties.RPMainConfDirectory -ChildPath ($Properties.UserGridProperties).Replace("user", $Server.Hostname)
    Out-Hashtable -Hashtable $GridProperties -Path $UserGridPath -Encoding "UTF8"
    Write-Log -Type "DEBUG" -Object $UserGridPath
    return $UserGridPath
  }
}
