locals {
  aws_alb_contoller = {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
}

module "aws_lb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "lb-controller-${var.cluster_name}"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    k8s = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.aws_alb_contoller.namespace}:${local.aws_alb_contoller.name}"]
    }
  }
}

resource "helm_release" "lb-controller" {
  namespace = local.aws_alb_contoller.namespace

  name       = "eks"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"

  values = [yamlencode({
    clusterName = var.cluster_name
    serviceAccount = {
      create      = true
      name        = local.aws_alb_contoller.name
      annotations = { "eks.amazonaws.com/role-arn" = module.aws_lb_controller_irsa.iam_role_arn }
    }
    tolerations = [{ key = local.eks.critical_addons_taint, operator = "Exists" }]
  })]

  depends_on = [
    helm_release.karpenter,
  ]
}
