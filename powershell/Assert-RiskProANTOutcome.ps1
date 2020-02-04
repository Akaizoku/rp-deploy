function Assert-RiskProANTOutcome {
  <#
    .SYNOPSIS
    Assert RiskPro ANT client command outcome

    .DESCRIPTION
    Assert outcome of RiskPro ANT client operation

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
    File name:      Assert-RiskProANTOutcome.ps1
    Author:         Florian Carrier
    Creation date:  20/12/2019
    Last modified:  20/12/2019
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
    # If (at least one) operation fails
    if (Select-String -InputObject $Log -Pattern '"outcome" => "failed"' -SimpleMatch -Quiet) {
      # If [WFLYCTL0212: Duplicate resource] or [WFLYCTL0158: already registered]
      if ((Select-String -InputObject $Log -Pattern '"failure-description" => "WFLYCTL0212: Duplicate resource' -SimpleMatch -Quiet) -Or (Select-String -InputObject $Log -Pattern '("failure-description" => "WFLYCTL0158:).*(is already registered)' -Quiet)) {
        if ($Quiet) {
          return $true
        } else {
          Write-Log -Type "WARN" -Object "$Object $FormattedDuplicate $FormattedVerb"
        }
      }
      # If unmanaged error
      else {
        if ($Quiet) {
          return $false
        } else {
          Write-Log -Type "ERROR" -Object "$Object could not be $FormattedVerb"
          Write-Log -Type "ERROR" -Object $Log -ExitCode 1
        }
      }
    }
    # If operation is successfull
    elseif (Select-String -InputObject $Log -Pattern '"outcome" => "success"' -SimpleMatch -Quiet) {
      if ($Quiet) {
        return $true
      } else {
        Write-Log -Type "CHECK" -Object "$Object $FormattedSuccess $FormattedVerb"
      }
    }
    # Case when no outcome status is provided but build is successfull
    elseif (Select-String -InputObject $Log -Pattern 'BUILD SUCCESSFUL' -SimpleMatch -Quiet) {
      if ($Quiet) {
        return $true
      } else {
        Write-Log -Type "CHECK" -Object "$Object $FormattedSuccess $FormattedVerb"
      }
    }
    # Case when no outcome status is provided
    else {
      Write-Log -Type "ERROR" -Object $Log -ExitCode 1
    }
  }
}
