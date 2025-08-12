#!/usr/bin/env bats
load 'test_helper/common.bash'

# bats file_tags=terraform

@test "Terraform via tenv" {
  run tenv tf list
  assert_success
}

@test "TFLint" { check_binary tflint; }

@test "terraform-docs" { check_binary terraform-docs; }

@test "terraform-config-inspect" {
  run terraform-config-inspect --json
  assert_success
}

@test "TFSec CLI" { check_binary tfsec; }

@test "tfsec can scan a minimal Terraform project" {
  tmpdir="$(mktemp -d)"

  cat >"$tmpdir/main.tf" <<'HCL'
terraform {
  required_version = ">= 1.0.0"
}
resource "null_resource" "ok" {}
HCL

  outbase="$tmpdir/tfsec-out"

  # Write JSON to a file; ignore stdout so banners can't break parsing.
  run bash -lc 'tfsec --no-color --no-module-downloads --format json --out "$1" "$2" >/dev/null' _ "$outbase" "$tmpdir"
  assert_success

  # tfsec may treat --out as base name (producing tfsec-out.json) or exact path.
  if [[ -f "$outbase" ]]; then
    report="$outbase"
  elif [[ -f "$outbase.json" ]]; then
    report="$outbase.json"
  else
    echo "tfsec did not write a report to $outbase or $outbase.json"
    false
  fi

  # Ensure valid JSON
  run jq -e '.' "$report"
  assert_success

  # Sanity: the JSON has a "results" key (current tfsec JSON schema)
  run jq -e 'has("results")' "$report"
  assert_success
}
