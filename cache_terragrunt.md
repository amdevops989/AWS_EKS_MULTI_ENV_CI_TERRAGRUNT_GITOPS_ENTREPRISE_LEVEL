mkdir -p ~/.terraform.d/plugin-cache

# 1. Append the export to .zshrc
echo 'export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"' >> ~/.zshrc

# 2. Reload the zsh configuration
source ~/.zshrc

# 3. Verify the variable is active
echo $TF_PLUGIN_CACHE_DIR


find . -type d -name ".terragrunt-cache" -prune -exec rm -rf {} +  in case you wanna restart fresher 


terragrunt state rm aws_ssm_parameter.rds_secret_arn