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