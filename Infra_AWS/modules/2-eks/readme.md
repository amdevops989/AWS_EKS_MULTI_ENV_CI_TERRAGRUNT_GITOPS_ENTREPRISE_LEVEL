aws eks list-access-entries --cluster-name ironcore-dev --profile devops --region us-east-1

 aws eks list-associated-access-policies \                                                  
  --cluster-name ironcore-dev \
  --principal-arn "arn:aws:iam::272495906318:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_DevOps-AdministratorAccess_a8154c80336f8ef7" \
  --profile devops \
--region us-east-1


aws eks update-kubeconfig \
--region us-east-1 \
--name ironcore-dev \
--profile devops
