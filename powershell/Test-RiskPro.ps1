function Test-RiskPro {
  <#
    .SYNOPSIS
    Test RiskPro

    .DESCRIPTION
    Check that a specified RiskPro platform is working as expected.

    .PARAMETER Properties
    The properties parameter corresponds to the configuration of the environment.

    .PARAMETER RiskProBatchClientProperties
    The RiskPro batch client properties parameter corresponds to the properties of the RiskPro batch client.

    .PARAMETER Unattended
    The unattended switch specifies if the script should run in non-interactive mode.

    .NOTES
    File name:      Test-RiskPro.ps1
    Author:         Florian Carrier
    Creation date:  22/01/2020
    Last modified:  07/02/2020
  #>
  [CmdletBinding(
    SupportsShouldProcess = $true
  )]
  Param(
    [Parameter (
      Position    = 1,
      Mandatory   = $true,
      HelpMessage = "Environment properties"
    )]
    [System.Collections.Specialized.OrderedDictionary]
    $Properties,
    [Parameter (
      Position    = 2,
      Mandatory   = $true,
      HelpMessage = "RiskPro batch client properties"
    )]
    [System.Collections.Specialized.OrderedDictionary]
    $RiskProBatchClientProperties,
    [Parameter (
      HelpMessage = "Non-interactive mode"
    )]
    [Switch]
    $Unattended
  )
  Begin {
    # Get global preference variables
    Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    # Parameters
    $EncryptionKey    = Get-Content -Path (Join-Path -Path $Properties.SecurityDirectory -ChildPath $Properties.EncryptionKey) -Encoding "UTF8"
    $ErrorCount       = 0
    $ISOTimeStamp     = Get-Date -Format "dd-MM-yyyy_HHmmss"
    $StaticExportFile = $Properties.StaticSolveName + "" + $ISOTimeStamp
  }
  Process {
    # Smoke testing
    Write-Log -Type "INFO" -Object "Smoke testing RiskPro $($Properties.RiskProVersion)"
    # Check RiskPro batch client path
    if (-Not (Test-Path -Path $RiskProBatchClientProperties.RiskProBatchClientPath)) {
      Write-Log -Type "ERROR" -Object "Path not found $($RiskProBatchClientProperties.RiskProBatchClientPath)"
      if (Test-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope) {
        Write-Log -Type "WARN" -Object "Defaulting to $($Properties.RiskProHomeVariable)"
        $RiskProHome = Get-EnvironmentVariable -Name $Properties.RiskProHomeVariable -Scope $Properties.EnvironmentVariableScope
        $RiskProBatchClientProperties.RiskProBatchClientPath = Join-Path -Path $RiskProHome -ChildPath "bin\riskpro-batch-client.jar"
      } else {
        Write-Log -Type "ERROR" -Object "Please check the script configuration" -ExitCode 1
      }
    }
    # --------------------------------------------------------------------------
    # Check RiskPro platform
    Write-Log -Type "INFO" -Object "Checking RiskPro platform accessibility"
    if (-Not (Test-HTTPStatus -URI $RiskProBatchClientProperties.ServerURI)) {
      Write-Log -Type "ERROR" -Object "Unable to reach RiskPro platform ($($RiskProBatchClientProperties.ServerURI))" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Check RiskPro batch client admin credentials
    Write-Log -Type "DEBUG" -Object "Validate RiskPro admin user credentials"
    $RiskProAdminCredentials = Get-ScriptCredentials -UserName "admin" -Password $Properties.DefaultAdminPassword -EncryptionKey $EncryptionKey -Label "RiskPro administration user" -Unattended
    $UnlockUser = Unlock-User -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -UserName $RiskProAdminCredentials.UserName
    if (-Not (Test-RiskProBatchClientOutcome -Log $UnlockUser)) {
      # Check if user is locked
      if (Select-String -InputObject $UnlockUser -Pattern '"User has been locked"' -SimpleMatch -Quiet) {
        Write-Log -Type "ERROR" -Object "RiskPro user ""$($RiskProAdminCredentials.UserName)"" is locked" -ExitCode 1
      } else {
        Write-Log -Type "ERROR" -Object "Invalid credentials for RiskPro user ""$($RiskProAdminCredentials.UserName)""" -ExitCode 1
      }
    }
    # --------------------------------------------------------------------------
    # Create test user
    Write-Log -Type "INFO" -Object "Creating test user ""$($Properties.TestUserName)"""
    $RiskProTestCredentials = Get-ScriptCredentials -UserName $Properties.TestUserName -Password $Properties.TestUserPassword -EncryptionKey $EncryptionKey -Label "RiskPro test user" -Unattended
    $DeleteUser = Invoke-DeleteUser -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -UserName $RiskProTestCredentials.UserName
    if (Test-RiskProBatchClientOutcome -Log $DeleteUser) {
      Write-Log -Type "WARN" -Object "Overwritting existing user ""$($RiskProTestCredentials.UserName)"""
    }
    $CreateUser = Invoke-CreateUser -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -UserName $RiskProTestCredentials.UserName -EmployeeName $Properties.TestUserFullName -UserGroups $Properties.AdminUserGroup
    if (Test-RiskProBatchClientOutcome -Log $CreateUser) {
      # Set test user password
      Write-Log -Type "DEBUG" -Object "Set test user password"
      $SetUserPassword = Set-UserPassword -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -UserName $RiskProTestCredentials.UserName -Password $RiskProTestCredentials.GetNetworkCredential().Password
      Assert-RiskProBatchClientOutcome -Log $SetUserPassword -Object """$($Properties.TestUserName)"" user" -Verb "create"
    } else {
      Write-Log -Type "ERROR" -Object $CreateUser
      Write-Log -Type "WARN" -Object """$($Properties.TestUserName)"" user could not be created" -ExitCode 1
    }
    # --------------------------------------------------------------------------
    # Check if test model exists
    # WARNING Use admin user to avoid permission issues
    Write-Log -Type "DEBUG" -Object "Check if test model already exists"
    if (Test-Model -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelName $Properties.TestModelName) {
      Write-Log -Type "WARN" -Object "Overwritting existing test model ""$($Properties.TestModelName)"""
      $ModelDeletion = Invoke-DeleteModel -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelName $Properties.TestModelName
      Assert-RiskProBatchClientOutcome -Log $ModelDeletion -Object """$($Properties.TestModelName)"" model" -Verb "delete"
    }
    # Create ALM template model
    Write-Log -Type "INFO" -Object "Creating test model ""$($Properties.TestModelName)"""
    # WARNING Wait for deletion to complete to avoid "com.microsoft.sqlserver.jdbc.SQLServerException: The INSERT statement conflicted with the FOREIGN KEY constraint "FK_TNG_MODEL_GROUPING2". The conflict occurred in database "RiskPro", table "dbo.MODEL", column 'MODEL_ID'."
    Start-Sleep -Seconds 10
    $CreateModel = Invoke-CreateModel -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelName $Properties.TestModelName -Type $Properties.TestModelType -Description $Properties.TestModelDescription -Currency $Properties.TestModelCurrency -Template $Properties.TestModelTemplate -ModelGroupName $Properties.SystemModelGroup
    Assert-RiskProBatchClientOutcome -Log $CreateModel -Object """$($Properties.TestModelName)"" model" -Verb "create"
    # --------------------------------------------------------------------------
    # Run static analysis
    Write-Log -Type "INFO" -Object "Starting static analysis ($($Properties.StaticSolveName))"
    $StaticSolve = Start-Solve -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelName $Properties.TestModelName -ResultSelection $Properties.StaticSolveName -AccountStructure "WBR1" -SolveName "Static Analysis" -AnalysisDate "01/04/2010 AM" -dataGroups "Current BS" -DataFilters "" -Kind "Static" -DeleteResults -Persistent -SynchronousMode
    if (Test-RiskProBatchClientOutcome -Log $StaticSolve) {
      Write-Log -Type "CHECK" -Object "Static analysis run successfully"
    } else {
      Write-Log -Type "ERROR" -Object "$($Properties.StaticSolveName) static analysis failed"
      $ErrorCount = $ErrorCount + 1
      # Check if user wants to carry on
      if (-Not $Unattended) {
        $Continue = Confirm-Prompt -Prompt "Do you want to continue smoke testing?"
        if (-Not $Continue) {
          Write-Log -Type "WARN" -Object "Smoke test aborted by user" -ExitCode 1
        }
      }
    }
    # --------------------------------------------------------------------------
    # Export results
    # WARNING com.frsglobal.pub.exception.UnsupportedBatchOperationException: Unsupported operation: 'startExportToExcel'.
    # Write-Log -Type "INFO" -Object "Exporting report to Excel"
    # $ExcelExport = Start-ExportToExcel -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelName $Properties.TestModelName -SolveJobName "Excel Export" -ReportedSolveJobName "Static Analysis" -ReportedSolveJobKind "STATIC" -ReportType "STATIC_BOOK_VALUE" -OutputFileName $StaticExportFile
    # Assert-RiskProBatchClientOutcome -Log $ExcelExport -Object "Excel report" -Verb "export"
    # --------------------------------------------------------------------------
    # Download results
    # TODO
    # --------------------------------------------------------------------------
    # Compare report with expected results using ExcelComparator
    # TODO
    # --------------------------------------------------------------------------
    # Run dynamic analysis
    Write-Log -Type "INFO" -Object "Starting dynamic analysis ($($Properties.DynamicSolveName))"
    $DynamicSolve = Start-Solve -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -ModelName $Properties.TestModelName -ResultSelection $Properties.DynamicSolveName -AccountStructure "WBR1" -SolveName "Dynamic Analysis" -AnalysisDate "01/04/2010 AM" -DataGroups "Current BS" -DataFilters "" -Kind "Dynamic" -DeleteResults -Persistent -SynchronousMode
    if (Test-RiskProBatchClientOutcome -Log $DynamicSolve) {
      Write-Log -Type "CHECK" -Object "Dynamic analysis run successfully"
    } else {
      Write-Log -Type "ERROR" -Object "$($Properties.DynamicSolveName) dynamic analysis failed"
      $ErrorCount = $ErrorCount + 1
      # Check if user wants to carry on
      if (-Not $Unattended) {
        $Continue = Confirm-Prompt -Prompt "Do you want to continue smoke testing?"
        if (-Not $Continue) {
          Write-Log -Type "WARN" -Object "Smoke test aborted by user" -ExitCode 1
        }
      }
    }
    # # --------------------------------------------------------------------------
    # # Delete test model
    # Write-Log -Type "INFO" -Object "Removing test model ""$($Properties.TestModelName)"""
    # $ModelDeletion = Invoke-DeleteModel -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -Name $Properties.TestModelName
    # Assert-RiskProBatchClientOutcome -Log $ModelDeletion -Object """$($Properties.TestModelName)"" model" -Verb "delete"
    # # --------------------------------------------------------------------------
    # # Delete test user
    # Write-Log -Type "INFO" -Object "Removing test user ""$($Properties.TestUserName)"""
    # $UserDeletion = Invoke-DeleteUser -JavaPath $Properties.JavaPath -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions -UserName $Properties.TestUserName
    # Assert-RiskProBatchClientOutcome -Log $UserDeletion -Object """$($Properties.TestUserName)"" user" -Verb "delete"
    # # --------------------------------------------------------------------------
    # # Run maintenance
    # Write-Log -Type "INFO" -Object "Starting maintenance"
    # $StartMaintenance = Start-Maintenance -RiskProBatchClient $RiskProBatchClientProperties.RiskProBatchClientPath -ServerURI $RiskProBatchClientProperties.ServerURI -Credentials $RiskProAdminCredentials -JavaOptions $RiskProBatchClientProperties.JavaOptions
    # Assert-RiskProBatchClientOutcome -Log $StartMaintenance -Object "Maintenance" -Verb "start"
  }

  End {
    # Check smoke test results
    if ($ErrorCount -eq 0) {
      Write-Log -Type "CHECK" -Object "Smoke test completed successfully"
    } else {
      Write-Log -Type "WARN" -Object "$ErrorCount errors occurred"
      Write-Log -Type "ERROR" -Object "Smoke test failed" -ExitCode 1
    }
  }
}
