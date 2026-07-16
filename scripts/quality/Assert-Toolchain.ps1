Set-StrictMode -Version Latest

function Read-QualityJson {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "JSON file does not exist: $Path"
  }

  try {
    return Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 100 -ErrorAction Stop
  } catch {
    throw "Invalid JSON in '$Path': $($_.Exception.Message)"
  }
}

function Invoke-IdentityCommand {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet('moon', 'moonc', 'moonrun')][string]$Command,
    [Parameter(Mandatory)][string[]]$Arguments
  )

  $lines = @(& $Command @Arguments 2>&1 | ForEach-Object { $_.ToString().TrimEnd() })
  if ($LASTEXITCODE -ne 0) {
    throw "Tool identity command failed: $Command $($Arguments -join ' ') (exit $LASTEXITCODE)"
  }
  return ,$lines
}

function Assert-ExactLines {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Label,
    [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Actual,
    [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$Expected
  )

  $normalizedActual = @($Actual | Where-Object { $_ -ne '' })
  if ($normalizedActual.Count -ne $Expected.Count) {
    throw "$Label identity produced $($normalizedActual.Count) non-empty line(s); expected $($Expected.Count). Actual: $($normalizedActual -join ' | ')"
  }
  for ($index = 0; $index -lt $Expected.Count; $index++) {
    if ($normalizedActual[$index] -cne $Expected[$index]) {
      throw "$Label identity mismatch at line $($index + 1). Expected '$($Expected[$index])'; got '$($normalizedActual[$index])'."
    }
  }
}

function Assert-Toolchain {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$PolicyPath)

  if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw "PowerShell 7 or newer is required; found $($PSVersionTable.PSVersion)."
  }

  $policy = Read-QualityJson -Path $PolicyPath
  foreach ($tool in @('moon', 'moonc', 'moonrun')) {
    if ($null -eq $policy.toolchain.$tool) {
      throw "Toolchain policy is missing '$tool'."
    }
  }

  $moonExpected = @(
    "moon $($policy.toolchain.moon.version) ($($policy.toolchain.moon.commit) $($policy.toolchain.moon.release_date))",
    'Feature flags enabled: rr_moon_mod,rr_moon_pkg'
  )
  $mooncExpected = @("$($policy.toolchain.moonc.version) ($($policy.toolchain.moonc.release_date))")
  $moonrunExpected = @("moonrun $($policy.toolchain.moonrun.version) ($($policy.toolchain.moonrun.commit) $($policy.toolchain.moonrun.release_date))")

  Assert-ExactLines -Label 'moon' -Actual (Invoke-IdentityCommand -Command moon -Arguments @('version')) -Expected $moonExpected
  Assert-ExactLines -Label 'moonc' -Actual (Invoke-IdentityCommand -Command moonc -Arguments @('-v')) -Expected $mooncExpected
  Assert-ExactLines -Label 'moonrun' -Actual (Invoke-IdentityCommand -Command moonrun -Arguments @('--version')) -Expected $moonrunExpected

  Write-Host "Toolchain verified: $($moonExpected[0]); $($mooncExpected[0]); $($moonrunExpected[0])"
}
