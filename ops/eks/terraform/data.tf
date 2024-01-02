data "utils_deep_merge_yaml" "vars" {
  input = [
    file("vars/defaults.yaml"),
    file("vars/${terraform.workspace}.yaml"),
  ]
}

data "aws_organizations_organization" "orgs" {
  provider = aws.mgmt
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.mgmt
}

# the role names are like AWSReservedSSO_${ROLE}_${random_stuff}
data "aws_iam_roles" "sso_roles" {
  name_regex  = "AWSReservedSSO_*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
