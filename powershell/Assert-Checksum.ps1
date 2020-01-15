function Assert-Checksum {
  <#
    .SYNOPSIS
    Check checksum

    .DESCRIPTION
    Check the distribution file against a reference checksum file

    .PARAMETER Properties
    The properties parameter corresponds to the application configuration.

    .NOTES
    File name:      Assert-Checksum.ps1
    Author:         Florian Carrier
    Creation date:  16/12/2019
    Last modified:  16/12/2019
  #>
  [CmdletBinding (
    SupportsShouldProcess = $true
  )]
  Param (
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "List of properties"
    )]
    [ValidateNotNullOrEmpty ()]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "Type"
    )]
    [ValidateSet (
      "Migrator",
      "RiskPro"
    )]
    [String]
    $Type
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Check type
    switch ($Type) {
      "Migrator" {
        $Distribution = $Properties.MigratorDistribution
        $Version = $Properties.RiskProMigratorVersion
        $Product = "Migrator tool"
      }
      "RiskPro" {
        $Distribution = $Properties.RiskProDistribution
        $Version = $Properties.RiskProVersion
        $Product = "RiskPro"
      }
    }
    # Distribution file path
    $DistributionFile = Join-Path -Path $Properties.SrcDirectory -ChildPath $Distribution
    # Checksum reference file
    $FileHashName = $Distribution + "." + (Format-String -String $Properties.ChecksumAlgorithm -Format "LowerCase")
  }
  Process {
    if (Test-Object -Path $Properties.ChecksumDirectory) {
      # Search for reference file in checksum local directory
      $FileHashPath = Join-Path -Path $Properties.ChecksumDirectory -ChildPath $FileHashName
      # If no packaged checksum file is found
      if (-Not (Test-Path -Path $FileHashPath)) {
        Write-Log -Type "DEBUG" -Object "No reference file found in $($Properties.ChecksumDirectory)"
        # Search for reference file in source directory
        $FileHashPath = Join-Path -Path $Properties.SrcDirectory -ChildPath $FileHashName
        if (-Not (Test-Path -Path $FileHashPath)) {
          Write-Log -Type "DEBUG" -Object "No reference file found in $($Properties.SrcDirectory)"
          Write-Log -Type "WARN"  -Object "No reference checksum file was found for $Product version $Version"
          Write-Log -Type "ERROR" -Object "$Product version $Version cannot be installed" -ExitCode 1
        }
      }
      # Get reference file hash
      Write-Log -Type "DEBUG" -Object $FileHashPath
      $ReferenceFileHash = Get-Content -Path $FileHashPath -Encoding "UTF8" -Raw
      Write-Log -Type "DEBUG" -Object "Reference checksum:`t`t`t`t$ReferenceFileHash"
      # Check that file is not corrupted
      $FileHash = Get-FileHash -Path $DistributionFile -Algorithm $Properties.ChecksumAlgorithm | Select-Object -ExpandProperty "Hash"
      Write-Log -Type "DEBUG" -Object "Distribution checksum:`t$FileHash"
      # /!\ Trim reference file hash to prevent formatting issues
      if ($FileHash -eq $ReferenceFileHash.Trim()) {
        Write-Log -Type "CHECK" -Object "Distribution file integrity check successful"
      } else {
        Write-Log -Type "ERROR" -Object "The distribution file $Distribution is corrupted" -ExitCode 1
      }
    } else {
      Write-Log -Type "ERROR" -Object "Path not found $($Properties.ChecksumDirectory)" -ExitCode 1
    }
  }
}
