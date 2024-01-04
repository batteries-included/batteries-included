locals {
  ebs_csi = {
    name      = "ebs-csi-controller"
    namespace = "kube-system"
  }
}

module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "ebs-csi-${var.cluster_name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    k8s = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.ebs_csi.namespace}:${local.ebs_csi.name}-sa"]
    }
  }
}
