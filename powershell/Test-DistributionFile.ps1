function Test-DistributionFile {
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Path to the distribution file to check"
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $Path,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Path to the directory containing checksum reference files"
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $Properties
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Get file name
    $FileName = $Path.BaseName
  }
  Process {
    # ----------------------------------------------------------------------
    # Check sources
    # ----------------------------------------------------------------------
    Write-Log -Type "INFO" -Object "Checking distribution file $FileName"
    if (-Not (Test-Object -Path $Path)) {
      Write-Log -Type "ERROR" -Object "Path not found $Path" -ErrorCode 1
    }
    # Check filesum
    if ($Properties.ChecksumCheck -eq "true") {
      if (Test-Object -Path $Properties.ChecksumDirectory) {
        $FileHashName = $RiskProDistribution + "." + (Format-String -String $Properties.ChecksumAlgorithm -Format "LowerCase")
        $FileHashPath = Join-Path -Path $Properties.ChecksumDirectory -ChildPath $FileHashName
        if (Test-Path -Path $FileHashPath) {
          # Get reference file hash
          $ReferenceFileHash = Get-Content -Path $FileHashPath -Encoding "UTF8" -Raw
          Write-Log -Type "DEBUG" -Object "Reference checksum:`t`t`t`t$ReferenceFileHash"
          # Check that file is not corrupted
          $FileHash = Get-FileHash -Path $Path -Algorithm $Properties.ChecksumAlgorithm | Select-Object -ExpandProperty "Hash"
          Write-Log -Type "DEBUG" -Object "Distribution checksum:`t$FileHash"
          # /!\ Trim reference file hash to prevent formatting issues
          if ($FileHash -ne $ReferenceFileHash.Trim()) {
            Write-Log -Type "ERROR" -Object "The distribution file is corrupted" -ErrorCode 1
          }
        } else {
          Write-Log -Type "WARN"  -Object "No checksum was found for RiskPro version $($Properties.RiskProVersion)"
          Write-Log -Type "ERROR" -Object "RiskPro version $($Properties.RiskProVersion) cannot be installed" -ErrorCode 1
        }
      } else {
        Write-Log -Type "ERROR" -Object "Path not found $($ReferencePath)" -Errorcode 1
      }
    } else {
      Write-Log -Type "WARN" -Object "Skipping source files integrity check"
    }
  }
}
