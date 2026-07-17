[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# RED contract: the completed checker must enforce these stable rule IDs against
# the real repository and generated temporary mutations. This sentinel is
# removed by the GREEN implementation in the next atomic commit.
$requiredRuleIds = @(
  'QUAL04-DOC-REQUIRED',
  'QUAL04-MANIFEST-METADATA',
  'QUAL04-SUPPORT-MATRIX',
  'QUAL04-PACKAGE-DAG',
  'QUAL04-FIXTURE-PROVENANCE',
  'QUAL04-EXAMPLE-RUNNABLE',
  'QUAL04-CLAIM-BOUNDARY'
)

if ($requiredRuleIds.Count -ne 7) {
  throw '[QUAL04-RULESET] Candidate documentation rule inventory drifted.'
}

throw '[QUAL04-CHECKER-UNIMPLEMENTED] Candidate documentation validator has not been implemented.'
