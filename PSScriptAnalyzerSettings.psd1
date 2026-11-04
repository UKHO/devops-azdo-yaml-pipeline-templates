@{
  # Errors and warnings fail the build. Information-level findings are not reported.
  Severity            = @('Error', 'Warning')
  IncludeDefaultRules = $true

  # Scripts in this repo are run by agents and written for console output.
  # PSUseApprovedVerbs / PSUseSingularNouns: the test framework's public entry points
  # (Run-Tests, Run-DirectoryCompileTests, Throw-On..., Evaluate-...) are referenced by every
  # *.CompileTests.ps1 file and by the contributor docs, so renaming them is not worth the churn.
  ExcludeRules        = @(
    'PSAvoidUsingWriteHost'
    'PSUseApprovedVerbs'
    'PSUseSingularNouns'
  )

  Rules               = @{
    PSPlaceOpenBrace           = @{
      Enable             = $true
      OnSameLine         = $false
      NewLineAfter       = $true
      IgnoreOneLineBlock = $true
    }

    PSPlaceCloseBrace          = @{
      Enable             = $true
      NewLineAfter       = $true
      IgnoreOneLineBlock = $true
      NoEmptyLineBefore  = $false
    }

    PSUseConsistentIndentation = @{
      Enable              = $true
      Kind                = 'space'
      IndentationSize     = 2
      PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
    }

    PSUseConsistentWhitespace  = @{
      Enable                          = $true
      CheckInnerBrace                 = $true
      CheckOpenBrace                  = $true
      CheckOpenParen                  = $true
      CheckOperator                   = $true
      CheckPipe                       = $true
      CheckPipeForRedundantWhitespace = $false
      CheckSeparator                  = $true
      CheckParameter                  = $false
      IgnoreAssignmentOperatorInsideHashTable = $true
    }
  }
}
