# ------------------------------------------------------------------------------
# Setup jboss.xml file
# ------------------------------------------------------------------------------
function Set-JBossConfig {
  [CmdletBinding ()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "System information"
    )]
    [ValidateNotNullOrEmpty()]
    [System.Collections.Specialized.OrderedDictionary]
    $System,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Path to the XML file"
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $XML,
    [Parameter (
      Position    = 3,
      Mandatory   = $false,
      HelpMessage = "XPath to the XML nodes to process"
    )]
    [String]
    $XPath = "project/property"
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $XMLFile = New-Object -TypeName "System.XML.XMLDocument"
    $XMLFile.Load($XML)
    $XMLNodes = Select-XMLNode -XML $XMLFile -XPath $XPath
    $Value = $null
  }
  Process {
    # Configure web-server XML variables
    foreach ($XMLNode in $XMLNodes) {
      # Map XML properties
      switch ($XMLNode.Name) {
        "jboss.host"        { $Value = $System.Hostname   }
        "jboss.port.http"   { $Value = $System.HTTPPort   }
        "jboss.port.admin"  { $Value = $System.AdminPort  }
      }
      # Update configuration
      if ($Value) {
        $XMLNode.Value = $Value
        Write-Log -Type "DEBUG" -Object "$($XMLNode.Name)=$($XMLNode.Value)"
      }
      # Reset configuration property variable
      $Value = $null
    }
    return $XMLFile
  }
}
