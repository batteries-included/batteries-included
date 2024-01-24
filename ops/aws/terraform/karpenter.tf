locals {
  karpenter = {
    discovery_key   = "karpenter.sh/discovery"
    discovery_value = var.cluster_name
  }
}

# "randomize" node TTLs so that all nodes across all clusters
# aren't going down simultaneously
resource "random_integer" "node_ttl" {
  min = 11
  max = 17

  seed = local.eks.cluster_name
  keepers = {
    cluster_version = local.eks.cluster_version
  }
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.0"

  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn

  # In v0.32.0/v1beta1, Karpenter now creates the IAM instance profile
  # so we disable the Terraform creation and add the necessary permissions for Karpenter IRSA
  enable_karpenter_instance_profile_creation = true

  # Used to attach additional IAM policies to the Karpenter node IAM role
  iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "v0.32.1"

  values = [yamlencode({
    settings = {
      clusterName           = module.eks.cluster_name
      clusterEndpoint       = module.eks.cluster_endpoint
      interruptionQueueName = module.karpenter.queue_name
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = module.karpenter.irsa_arn
      }
    }
  })]

  depends_on = [module.eks, ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2"
      role      = module.karpenter.role_name
      securityGroupSelectorTerms = [
        {
          tags = {
            (local.karpenter.discovery_key) = local.karpenter.discovery_value
          }
        },
      ]
      subnetSelectorTerms = [
        {
          tags = {
            (local.karpenter.discovery_key) = local.karpenter.discovery_value
          }
        },
      ]

      tags = merge(local.tags, { (local.karpenter.discovery_key) = local.karpenter.discovery_value })
    }
  })

  depends_on = [helm_release.karpenter, ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "default"
    }
    spec = {
      disruption = {
        consolidateAfter    = "30s"
        consolidationPolicy = "WhenEmpty"
        expireAfter         = "${random_integer.node_ttl.result}h"
      }
      limits = {
        cpu = 1000
      }
      template = {
        spec = {
          nodeClassRef = {
            name = kubectl_manifest.karpenter_node_class.name
          }
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64", ] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot", "on-demand", ] },
            { key = "karpenter.k8s.aws/instance-family", operator = "In", values = ["t3", "t3a", ] },
            { key = "karpenter.k8s.aws/instance-size", operator = "In", values = ["small", "medium", "large", ] },
            { key = "karpenter.k8s.aws/instance-hypervisor", operator = "In", values = ["nitro", ] },
          ]
        }
      }
    }
  })
}
