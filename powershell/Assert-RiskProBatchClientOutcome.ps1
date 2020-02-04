function Assert-RiskProBatchClientOutcome {
  <#
    .SYNOPSIS
    Assert RiskPro batch client command outcome

    .DESCRIPTION
    Assert outcome of RiskPro batch client operation

    .PARAMETER Log
    The log parameter corresponds to the output log of the operation performed.

    .PARAMETER Object
    The object parameter corresponds to the name of the resource affected.

    .PARAMETER Verb
    The verb parameter corresponds to the name of the operation performed.

    .PARAMETER IrregularForm
    The optional irregular form parameter corresponds to the past tense of the operational verb if it is irregular.

    .PARAMETER Plural
    The plural switch determines if the plural form should be used to describe the object.

    .NOTES
    File name:      Assert-RiskProBatchClientOutcome.ps1
    Author:         Florian Carrier
    Creation date:  20/01/2020
    Last modified:  23/01/2020
  #>
  [CmdletBinding()]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "JBoss client command output log"
    )]
    [ValidateNotNullOrEmpty()]
    [Object]
    $Log,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Name of the resource affected"
    )]
    [String]
    $Object,
    [Parameter (
      Position    = 3,
      Mandatory   = $true,
      HelpMessage = "Operation performed"
    )]
    [String]
    $Verb,
    [Parameter (
      Position    = 4,
      Mandatory   = $false,
      HelpMessage = "Past tense of the operational verb (if irregular)"
    )]
    [String]
    $IrregularForm,
    [Parameter (
      HelpMessage = "Flag whether the plural form should be used"
    )]
    [Switch]
    $Plural = $false,
    [Parameter (
      HelpMessage = "Flag to only check success state"
    )]
    [Switch]
    $Quiet
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Format output
    if ($PSBoundParameters["IrregularForm"]) {
      $FormattedVerb = Format-String -String $IrregularForm -Format "lowercase"
    } else {
      $Verb = Format-String -String $Verb -Format "lowercase"
      if ($Verb.SubString($Verb.Length - 1, 1) -eq "e") {
        $FormattedVerb = $Verb + "d"
      } else {
        $FormattedVerb = $Verb + "ed"
      }
    }
    if ($Plural) {
      $FormattedSuccess   = "have been successfully"
      $FormattedDuplicate = "are already"
    } else {
      $FormattedSuccess   = "has been successfully"
      $FormattedDuplicate = "is already"
    }
  }
  Process {
    # Check JBoss client operation outcome
    $Success = Test-RiskProBatchClientOutcome -Log $Log
    # If quiet mode
    if ($Quiet) {
      # Return outcome result (success=true/failure=false)
      return $Success
    } else {
      # Parse outcome
      if ($Success -eq $false) {
        # If operation failed
        Write-Log -Type "ERROR" -Object $Log
        Write-Log -Type "WARN"  -Object "$Object could not be $FormattedVerb" -ExitCode 1
      } else {
        # If operation is successfull
        Write-Log -Type "CHECK" -Object "$Object $FormattedSuccess $FormattedVerb"
      }
    }
  }
}
