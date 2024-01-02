locals {
  accounts = {
    for acct in data.aws_organizations_organization.orgs.accounts :
    acct.name => acct
  }
  target_account_id = local.accounts[local.vars.account].id

  tags = {
    environment = local.vars.account
    tier        = local.vars.tier
    terraform   = "eks-${terraform.workspace}"
  }
  # rearrange SSO roles by name for easier access
  sso_roles = { for i, name in data.aws_iam_roles.sso_roles.names : tolist(split("_", name))[1] => name }

  vars = yamldecode(data.utils_deep_merge_yaml.vars.output)
}
