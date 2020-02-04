function Resolve-SQLVariable {
  <#
    .SYNOPSIS
    Resolve SQL variable

    .DESCRIPTION
    Parse SQL variable to resolve NULL or empty values

    .PARAMETER Variable
    The variable parameter corresponds to the variable key-value pair to resolve.

    .NOTES
    File name:      Resolve-SQLVariable.ps1
    Author:         Florian Carrier
    Creation date:  15/10/2019
    Last modified:  16/01/2020
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Variable key-value pair"
    )]
    [ValidateNotNullOrEmpty ()]
    [Alias ("Variables")]
    [System.Collections.Specialized.OrderedDictionary]
    $Variable
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
  }
  Process {
    foreach ($Variable in $Variables.GetEnumerator()) {
      # # Resolve string values
      # if (($Variable.Value -As [Int]) -eq $null) {
      #   # Ignore string value NULL to avoid conflict
      #   if ($Variable.Value -ne "NULL") {
      #     $Variable.Value = "'" + $Variable.Value + "'"
      #   }
      # }
      # Resolve NULL values
      if ([String]::IsNullOrEmpty($Variable.Value)) {
        $Variable.Value = $null
      }
      # TODO fix empty values issue
      # Workaround: use -NullValue "NULL" in Import-CSVProperties
    }
    return $Variables
  }
}
