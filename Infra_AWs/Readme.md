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
