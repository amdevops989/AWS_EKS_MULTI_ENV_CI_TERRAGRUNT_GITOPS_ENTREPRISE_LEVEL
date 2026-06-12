## we gonna create github action cicd 

first : Create the OIDC Identity Provider in AWS

aws iam create-open-id-connect-provider \
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list "sts.amazonaws.com" \
  --profile devops-dev

Step 2: Create the IAM Role and Trust Policy

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::272495906318:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME_OR_ORG/AWS_EKS_MULTI_ENV_CI_TERRAGRUNT_GITOPS_ENTREPRISE_LEVE:*"
        }
      }
    }
  ]
}

Create the IAM Role via the CLI:

aws iam create-role \
  --role-name github-actions-infra-role \
  --assume-role-policy-document file://github-trust-policy.json \
  --profile devops-dev

3. Attach Permissions to the Role:

Since this role will be executing your Terragrunt infrastructure architectures (creating VPCs, S3 buckets, and EKS clusters), attach administrative permissions to it inside the sandbox boundary:

aws iam attach-role-policy \
  --role-name github-actions-infra-role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess \
  --profile devops-dev


To map your Git branches dynamically to their respective AWS accounts and profiles without duplicating code, we will use GitHub Actions Environments combined with branch protection rules.

Let's configure your dev branch to deploy exclusively to your Sandbox account (272495906318) using OIDC.

Step 1: Create the GitHub Environment
Go to your GitHub repository -> Settings -> Environments.

Click New environment and name it exactly: development.

Under Deployment branches, select Selected branches and add a rule for dev. (This ensures only workflows running on the dev branch can access this environment's secrets).

In the Environment secrets section at the bottom, click Add secret and add:

Name: AWS_ROLE_ARN

Value: arn:aws:iam::272495906318:role/github-actions-infra-role (The OIDC role we created in your sandbox account).