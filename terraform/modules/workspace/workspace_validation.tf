# https://github.com/hashicorp/terraform/issues/15469#issuecomment-507689324

# Assert that the user's workspace and environment match to avoiding
# accidentally applying the wrong vars / terraform to the wrong environment.

# Assumptions
# - local.allowed_env is set as a list of environments, e.g. ["dev", "prod"]
# - A var.env is defined, and is used as the backend's workspace_key_prefix.
# - Workspace names should match environment names.

variable "env" {
  type = string
}

locals {
  allowed_env = ["prod1", "test1"]
}

resource "null_resource" "assert_workspace_name_is_valid" {
  triggers = contains(local.allowed_env, terraform.workspace) ? {} : file("Assertion failed: Your workspace must be one of [${join(",", local.allowed_env)}]. Your current workspace is ${terraform.workspace}. Use 'terraform workspace select' or 'terraform workspace new' to choose the right workspace.")
  lifecycle {
    ignore_changes = [triggers]
  }
}

resource "null_resource" "assert_workspace_matches_var_file_env" {
  triggers = terraform.workspace == var.env ? {} : file("Assertion failed: The 'env' variable doesn't match the selected workspace. For example, if your workspace is 'prod', env must also 'prod'. Did you use the right 'tfvars' file?")
  lifecycle {
    ignore_changes = [triggers]
  }
}
