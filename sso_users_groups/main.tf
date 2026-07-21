terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # IAM Identity Center is deployed in us-east-1
}

# ------------------------------------------------------------------------------
# 1. FETCH EXISTING IAM IDENTITY CENTER INSTANCE
# ------------------------------------------------------------------------------
data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn      = data.aws_ssoadmin_instances.this.arns[0]
  sso_identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]

  # Account IDs from your AWS Console
  prod_account_id    = "315089529175" # IronCore (Prod)
  sandbox_account_id = "272495906318" # IronCoreSandboxDev (Dev/Sandbox)
}

# ------------------------------------------------------------------------------
# 2. CREATE GROUPS
# ------------------------------------------------------------------------------
resource "aws_identitystore_group" "devops" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "DevOps-Admins"
  description       = "Full administrative access across all accounts"
}

resource "aws_identitystore_group" "developers" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "Sandbox-Developers"
  description       = "Full access to Sandbox/Dev account and ReadOnly access to Prod account"
}

# ------------------------------------------------------------------------------
# 3. CREATE USERS & MEMBERSHIPS
# ------------------------------------------------------------------------------
resource "aws_identitystore_user" "lead_devops" {
  identity_store_id = local.sso_identity_store_id
  user_name         = "amounir.devops"
  display_name      = "Amounir DevOps"

  name {
    given_name  = "Amounir"
    family_name = "Mohamed"
  }

  emails {
    value   = "ironcoredigital@outlook.com"
    primary = true
  }
}



# Assign User to DevOps Group
resource "aws_identitystore_group_membership" "devops_member" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.devops.group_id
  member_id         = aws_identitystore_user.lead_devops.user_id
}

# ------------------------------------------------------------------------------
# 4. CREATE PERMISSION SETS
# ------------------------------------------------------------------------------
# Administrator Access Permission Set
resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdministratorAccess"
  description      = "Full Administrator Access"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ReadOnly Access Permission Set
resource "aws_ssoadmin_permission_set" "readonly" {
  name             = "ReadOnlyAccess"
  description      = "Read-Only Access for Production visibility"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ------------------------------------------------------------------------------
# 5. ACCOUNT ASSIGNMENTS
# ------------------------------------------------------------------------------

# --- DEVOPS GROUP (Full Access to Both Accounts) ---

# 1. DevOps Group -> Prod Account (AdministratorAccess)
resource "aws_ssoadmin_account_assignment" "devops_prod_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_group.devops.group_id
  principal_type = "GROUP"

  target_id   = local.prod_account_id
  target_type = "AWS_ACCOUNT"
}

# 2. DevOps Group -> Sandbox/Dev Account (AdministratorAccess)
resource "aws_ssoadmin_account_assignment" "devops_sandbox_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_group.devops.group_id
  principal_type = "GROUP"

  target_id   = local.sandbox_account_id
  target_type = "AWS_ACCOUNT"
}

# --- DEVELOPERS GROUP (Full Access to Dev, ReadOnly to Prod) ---

# 3. Developers Group -> Sandbox/Dev Account (AdministratorAccess)
resource "aws_ssoadmin_account_assignment" "dev_sandbox_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = aws_identitystore_group.developers.group_id
  principal_type = "GROUP"

  target_id   = local.sandbox_account_id
  target_type = "AWS_ACCOUNT"
}

# 4. Developers Group -> Prod Account (ReadOnlyAccess)
resource "aws_ssoadmin_account_assignment" "dev_prod_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn

  principal_id   = aws_identitystore_group.developers.group_id
  principal_type = "GROUP"

  target_id   = local.prod_account_id
  target_type = "AWS_ACCOUNT"
}