# 1. The Identity Governance Matrix ( AWS )

[Identity Directory]            [IAM Identity Center Groups]             [Target AWS Accounts & Permission Sets]

   ┌── devops ──┐                                                         ┌──> IronCore (Prod) ───────> AWSAdministratorAccess
   │            ├─── (Member of) ───>  DevOps-Team  ─── (Assigned to) ────┤
   └── ...    ──┘                                                         └──> IronCoreSandboxDev ───> AWSAdministratorAccess


   ┌── developer ┐                                                        ┌──> IronCore (Prod) ───────> AWSReadOnlyAccess
   │             ├─── (Member of) ───> Developer-Team ─── (Assigned to) ──┤
   └── ...     ──┘                                                        └──> IronCoreSandboxDev ───> AWSAdministratorAccess

## 2 Setting up the AWs Cli Profiles

aws configure sso


Because we operate in a multi-account AWS Organization environment, order of operations is critical. I use Terragrunt to provision the foundational layer—VPC, RDS, EKS, and IAM roles. Inside Kubernetes, I always deploy Cert-Manager first because admission controllers like Kyverno need TLS certificates to function. Next, I bring up Vault and External Secrets Operator so secrets are available before ArgoCD starts syncing applications. Once the security, mesh, and observability layers are healthy, ArgoCD manages the application lifecycle and progressive Canary rollouts