Based on your SSO architecture, here is how your **`access_entries`** configuration should look in your Terragrunt/EKS code for both the **`dev`** and **`prod`** environments.

---

### How AWS SSO IAM Roles Work with EKS

When users log in via IAM Identity Center (SSO), AWS dynamically generates IAM roles in the target accounts using this exact naming convention:

```text
arn:aws:iam::<ACCOUNT_ID>:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_<PERMISSION_SET_NAME>_<RANDOM_HASH>

```

Because both **`DevOps-Admins`** and **`Sandbox-Developers`** use the **`DevOps-AdministratorAccess`** PermissionSet in the **`dev`** account, they will assume the **exact same IAM Role ARN** in that account.

---

### 1. `dev` Environment (`access_entries`)

In your **`dev`** cluster (`ironcore-dev`), both DevOps and Developer users assume the `DevOps-AdministratorAccess` SSO role. You can either grant cluster admin permissions to both or break out access entries per role if you create a dedicated PermissionSet later.

```hcl
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # 1. Human SSO Admin & Developer Access
    # (Since both DevOps and Developer groups have AdministratorAccess in Sandbox/Dev account)
    sso_console_dev_admin = {
      principal_arn = "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps-AdministratorAccess_a8154c80336f8ef7"
      type          = "STANDARD"

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # 2. GitHub Actions CI/CD Access (Dev Pipeline)
    github_actions_cicd = {
      principal_arn = "arn:aws:iam::272495906318:role/github-actions-eks-deployer-role"
      type          = "STANDARD"

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

```

---

### 2. `prod` Environment (`access_entries`)

In your **`prod`** cluster (`ironcore-prod` on account `315089529175`), the roles are completely separated:

* **DevOps Admins** hold **`DevOps-AdministratorAccess`** $\rightarrow$ Full EKS Cluster Admin.
* **Developers** hold **`Developers-ReadOnlyAccess`** $\rightarrow$ EKS View / Read-Only Policy.

*(Note: Replace `<PROD_HASH_1>` and `<PROD_HASH_2>` with the actual SSO role hashes generated in your Prod AWS Account).*

```hcl
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # 1. DevOps Group (Full Cluster Admin in Prod)
    sso_console_prod_admin = {
      principal_arn = "arn:aws:iam::315089529175:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps-AdministratorAccess_<PROD_HASH_1>"
      type          = "STANDARD"

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # 2. Developers Group (ReadOnly Access in Prod)
    sso_console_prod_readonly = {
      principal_arn = "arn:aws:iam::315089529175:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_Developers-ReadOnlyAccess_<PROD_HASH_2>"
      type          = "STANDARD"

      policy_associations = {
        readonly_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # 3. GitHub Actions CI/CD Access (Prod Pipeline)
    github_actions_cicd = {
      principal_arn = "arn:aws:iam::315089529175:role/github-actions-eks-deployer-role"
      type          = "STANDARD"

      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

```

---

### Summary Scope Mapping

| Account / Cluster | SSO Group / Role | EKS Access Policy Attached | Resulting Permissions |
| --- | --- | --- | --- |
| **Dev (`272495906318`)** | `DevOps-Admins` | `AmazonEKSClusterAdminPolicy` | **Full Admin** |
| **Dev (`272495906318`)** | `Sandbox-Developers` | `AmazonEKSClusterAdminPolicy` | **Full Admin** |
| **Prod (`315089529175`)** | `DevOps-Admins` | `AmazonEKSClusterAdminPolicy` | **Full Admin** |
| **Prod (`315089529175`)** | `Sandbox-Developers` | `AmazonEKSViewPolicy` | **Read-Only / View** |