+-------------------+        1. OIDC Web Identity        +--------------------+
|  GitHub Actions   | ---------------------------------> |  AWS OIDC Provider |
|  CI/CD Pipeline   | <--------------------------------- |   & IAM Deployer   |
+-------------------+       2. Temp STS Credentials      +--------------------+
                                                                    |
                                                                    v
                                                         +--------------------+
                                                         | AWS Identity Center|
                                                         | (SSO Provisioning) |
                                                         +--------------------+
                                                                    |
                                        +---------------------------+---------------------------+
                                        |                                                       |
                                        v                                                       v
                          +---------------------------+                           +---------------------------+
                          |   DevOps-Admins Group     |                           |  Sandbox-Developers Group |
                          |  • Amounir DevOps User    |                           |  • App Developer User     |
                          +---------------------------+                           +---------------------------+
                                        |                                                       |
                    +-------------------+-------------------+               +-------------------+-------------------+
                    |                                       |               |                                       |
                    v                                       v               v                                       v
            [Prod Account]                         [Sandbox Account]  [Sandbox Account]                       [Prod Account]
          (AdminAccess Role)                      (AdminAccess Role) (AdminAccess Role)                     (ReadOnlyAccess Role)



Here is the full, comprehensive documentation formatted as a clean Markdown guide (`SSO_OIDC_ARCHITECTURE.md`). It covers everything we built: the S3/DynamoDB backend, the GitHub Actions OIDC identity provider, and the IAM Identity Center users, groups, and permission set assignments.

---

# AWS IAM Identity Center & OIDC Pipeline Architecture Guide

## 📌 Executive Summary

This architecture provides an automated, enterprise-grade Infrastructure-as-Code (IaC) setup for multi-account AWS access control. It combines:

1. **Remote Backend with Locking**: S3 bucket for state storage and DynamoDB for state locking.
2. **Passwordless CI/CD Authentication**: GitHub Actions connecting to AWS via OpenID Connect (OIDC) without long-lived access keys.
3. **Centralized Identity & Access Management**: AWS IAM Identity Center (SSO) managing users, groups, custom permission sets, and cross-account assignments across **Production** and **Sandbox** AWS accounts.

---

## 🏗 Architecture & Access Matrix

### 1. High-Level Architecture Flow

```
+--------------------------+          1. OIDC Token (JWT)          +--------------------------+
|                          | ------------------------------------> |                          |
|  GitHub Actions Runner   |                                       |   AWS OIDC Provider &    |
|  (amdevops989/Repository)| <------------------------------------ |  IAM Deployer Role       |
+--------------------------+       2. Temporary STS Credentials    +--------------------------+
             |                                                                  |
             | 3. Deploys IaC State                                             v
             v                                                     +--------------------------+
+--------------------------+                                       |  AWS IAM Identity Center |
|  S3 State + DynamoDB     |                                       |  (SSO Store & Engine)    |
|  State Lock Mechanism    |                                       +--------------------------+
+--------------------------+         



                                           |
                                                                                |
                                       +----------------------------------------+----------------------------------------+
                                       |                                                                                 |
                                       v                                                                                 v
                          +--------------------------+                                                      +--------------------------+
                          |   DevOps-Admins Group    |                                                      | Sandbox-Developers Group |
                          | • User: amounir.devops   |                                                      | • User: developer.user   |
                          +--------------------------+                                                      +--------------------------+
                                       |                                                                                 |
                    +------------------+------------------+                                           +------------------+------------------+
                    |                                     |                                           |                                     |
                    v                                     v                                           v                                     v
         [Prod Account: 315089529175]        [Sandbox Account: 272495906318]             [Sandbox Account: 272495906318]        [Prod Account: 315089529175]
           (DevOps-AdministratorAccess)        (DevOps-AdministratorAccess)               (DevOps-AdministratorAccess)           (Developers-ReadOnlyAccess)

```

### 2. Group & Account Assignment Matrix

| Group Name | Assigned Users | Target AWS Account | Permission Set Applied | Access Level |
| --- | --- | --- | --- | --- |
| **DevOps-Admins** | `amounir.devops` | **IronCore (Prod)** `315089529175` | `DevOps-AdministratorAccess` | Full Admin |
| **DevOps-Admins** | `amounir.devops` | **IronCoreSandboxDev** `272495906318` | `DevOps-AdministratorAccess` | Full Admin |
| **Sandbox-Developers** | `developer.user` | **IronCoreSandboxDev** `272495906318` | `DevOps-AdministratorAccess` | Full Admin (Dev Sandbox) |
| **Sandbox-Developers** | `developer.user` | **IronCore (Prod)** `315089529175` | `Developers-ReadOnlyAccess` | Read-Only Visibility |

---

## 💾 Section 1: Remote S3 & DynamoDB Backend

To support team collaboration, prevent concurrent pipeline runs from corrupting state, and enable state locking, Terraform uses a remote S3 backend backed by DynamoDB.

### Prerequisites (Created in AWS Console/CLI)

* **S3 Bucket Name**: `ironcore-terraform-state-us-east-1` (Versioning Enabled, Block All Public Access)
* **DynamoDB Table Name**: `ironcore-terraform-state-locks`
* **Partition Key**: `LockID` (Type: `String`)



### HCL Backend Configuration

```hcl
terraform {
  required_version = ">= 1.7.0"

  backend "s3" {
    bucket         = "ironcore-terraform-state-us-east-1"
    key            = "sso/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ironcore-terraform-state-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

```

---

## 🔑 Section 2: AWS OIDC Authentication for GitHub Actions

Instead of storing permanent `AWS_ACCESS_KEY_ID` secrets, GitHub Actions authenticates using OpenID Connect tokens issued on every workflow execution.

### OIDC Identity Provider & Role Definition

```hcl
# 1. AWS OpenID Connect Provider for GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a2a8515327c7a023924587363102a11b22e1"
  ]
}

# 2. IAM Role with Scoped Repository Trust Policy
resource "aws_iam_role" "github_actions" {
  name        = "GitHubActions-IdentityCenter-Deployer"
  description = "Role assumed by GitHub Actions for passwordless deployments"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Scope role assumption strictly to your repository
            "token.actions.githubusercontent.com:sub" = "repo:amdevops989/AWS_EKS_MULTI_ENV_CI_TERRAGRUNT_GITOPS_ENTREPRISE_LEVEL:*"
          }
        }
      }
    ]
  })
}

# 3. Attach Permissions Required for IAM Identity Center Provisioning
resource "aws_iam_role_policy_attachment" "github_sso_admin" {
  role       = aws_iam_role.github_actions.name
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSSSOAdminFullAccess"
}

resource "aws_iam_role_policy_attachment" "github_identity_store" {
  role       = aws_iam_role.github_actions.name
  managed_policy_arn = "arn:aws:iam::aws:policy/AWSIdentityStoreFullAccess"
}

```

---

## 👥 Section 3: IAM Identity Center (Users, Groups, & Permission Sets)

The main configuration manages groups, users, memberships, permission sets, and account assignments within AWS Identity Center.

### Complete `main.tf`

```hcl
# ==============================================================================
# DATA LOOKUPS & LOCALS
# ==============================================================================

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn      = data.aws_ssoadmin_instances.this.arns[0]
  sso_identity_store_id = data.aws_ssoadmin_instances.this.identity_store_ids[0]

  # Target AWS Account IDs
  prod_account_id    = "315089529175" # IronCore (Prod)
  sandbox_account_id = "272495906318" # IronCoreSandboxDev (Dev/Sandbox)
}

# ==============================================================================
# GROUPS
# ==============================================================================

resource "aws_identitystore_group" "devops" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "DevOps-Admins"
  description       = "Full administrative access across all organization accounts"
}

resource "aws_identitystore_group" "developers" {
  identity_store_id = local.sso_identity_store_id
  display_name      = "Sandbox-Developers"
  description       = "Full access to Sandbox/Dev account and ReadOnly access to Prod account"
}

# ==============================================================================
# USERS & MEMBERSHIPS
# ==============================================================================

# --- DevOps Lead User ---
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

resource "aws_identitystore_group_membership" "devops_member" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.devops.group_id
  member_id         = aws_identitystore_user.lead_devops.user_id
}

# --- Application Developer User ---
resource "aws_identitystore_user" "developer_user" {
  identity_store_id = local.sso_identity_store_id
  user_name         = "developer.user"
  display_name      = "App Developer"

  name {
    given_name  = "App"
    family_name = "Developer"
  }

  emails {
    value   = "developer@ironcoredigital.com"
    primary = true
  }
}

resource "aws_identitystore_group_membership" "developer_member" {
  identity_store_id = local.sso_identity_store_id
  group_id          = aws_identitystore_group.developers.group_id
  member_id         = aws_identitystore_user.developer_user.user_id
}

# ==============================================================================
# PERMISSION SETS
# ==============================================================================

# 1. Administrator Access Permission Set
resource "aws_ssoadmin_permission_set" "admin" {
  name             = "DevOps-AdministratorAccess"
  description      = "Full Administrator Access"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# 2. ReadOnly Access Permission Set
resource "aws_ssoadmin_permission_set" "readonly" {
  name             = "Developers-ReadOnlyAccess"
  description      = "Read-Only Access for Production visibility"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ==============================================================================
# ACCOUNT ASSIGNMENTS
# ==============================================================================

# --- DEVOPS GROUP (Full Access to Both Accounts) ---
resource "aws_ssoadmin_account_assignment" "devops_prod_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.devops.group_id
  principal_type     = "GROUP"
  target_id          = local.prod_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "devops_sandbox_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.devops.group_id
  principal_type     = "GROUP"
  target_id          = local.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

# --- DEVELOPERS GROUP (Full Access to Dev, ReadOnly to Prod) ---
resource "aws_ssoadmin_account_assignment" "dev_sandbox_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.developers.group_id
  principal_type     = "GROUP"
  target_id          = local.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "dev_prod_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  principal_id       = aws_identitystore_group.developers.group_id
  principal_type     = "GROUP"
  target_id          = local.prod_account_id
  target_type        = "AWS_ACCOUNT"
}

```

---

## ⚙️ Section 4: GitHub Actions Workflow Integration

In `.github/workflows/sso-deploy.yml`:

```yaml
name: "Terraform Apply SSO"

on:
  push:
    branches:
      - main
  pull_request:

permissions:
  id-token: write # Required for GitHub OIDC token generation
  contents: read

jobs:
  deploy:
    name: "Deploy IAM Identity Center"
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.7.0

      - name: Configure AWS Credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::315089529175:role/GitHubActions-IdentityCenter-Deployer
          aws-region: us-east-1
          role-session-name: GitHubActions-SSO-Deploy

      - name: Terraform Init
        run: terraform init

      - name: Terraform Format & Validate
        run: |
          terraform fmt -check
          terraform validate

      - name: Terraform Plan
        run: terraform plan -input=false

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'PUSH'
        run: terraform apply -auto-approve -input=false

```

---

## 🛠 Operational Troubleshooting Cheat Sheet

### 1. Releasing a Deadlock in DynamoDB State Lock

If a cancelled GitHub runner holds a lock, release it via AWS CLI:

```bash
aws dynamodb delete-item \
  --table-name ironcore-terraform-state-locks \
  --key '{"LockID": {"S": "ironcore-terraform-state-us-east-1/sso/terraform.tfstate-md5"}}'

```

### 2. Clearing Stuck Permission Sets in AWS SSO

If permission set creation hangs in GitHub Actions due to orphan background jobs in AWS:

```bash
INSTANCE_ARN=$(aws sso-admin list-instances --query "Instances[0].InstanceArn" --output text)

for ARN in $(aws sso-admin list-permission-sets --instance-arn $INSTANCE_ARN --query "PermissionSets[]" --output text); do
  NAME=$(aws sso-admin describe-permission-set --instance-arn $INSTANCE_ARN --permission-set-arn $ARN --query "PermissionSet.Name" --output text)
  if [ "$NAME" == "DevOps-AdministratorAccess" ]; then
    aws sso-admin delete-permission-set --instance-arn $INSTANCE_ARN --permission-set-arn $ARN
  fi
done

```

### 3. Setting User Passwords

Passwords are not managed inside Terraform for security reasons. Users automatically receive activation email invites. Alternatively, force password resets via AWS CLI:

```bash
IDENTITY_STORE_ID=$(aws sso-admin list-instances --query "Instances[0].IdentityStoreId" --output text)
USER_ID=$(aws identitystore list-users --identity-store-id $IDENTITY_STORE_ID --filter AttributePath="UserName",AttributeValue="developer.user" --query "Users[0].UserId" --output text)

aws identitystore reset-password --identity-store-id $IDENTITY_STORE_ID --user-id $USER_ID

```