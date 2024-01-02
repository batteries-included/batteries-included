locals {
  eks = {
    cluster_name    = "eks-${terraform.workspace}"
    cluster_version = "1.28"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = local.eks.cluster_name
  cluster_version                = local.eks.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa.iam_role_arn
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        resources = {
          limits   = { cpu = "0.25", memory = "256M" }
          requests = { cpu = "0.25", memory = "256M" }
        }
      })
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  kms_key_deletion_window_in_days = 7

  eks_managed_node_groups = {
    bootstrap = {
      name           = "${local.eks.cluster_name}-bootstrap"
      instance_types = local.vars.managed_node_group.instance_types

      min_size     = local.vars.managed_node_group.min_size
      max_size     = local.vars.managed_node_group.max_size
      desired_size = local.vars.managed_node_group.desired_size

      iam_role_additional_policies = {
        # Required by Karpenter
        ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      taints = {
        no_schedule_karpenter = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = [
    {
      rolearn  = module.karpenter.role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = "arn:aws:iam::${local.target_account_id}:role/${local.sso_roles["AdministratorAccess"]}"
      username = "admin:{{SessionName}}"
      groups = [
        "system:masters",
      ]
    },
    {
      rolearn  = "arn:aws:iam::${local.target_account_id}:role/${local.sso_roles["SystemAdministrator"]}"
      username = "power-user:{{SessionName}}"
      groups = [
        "engineers",
        "eks-console-dashboard-full-access",
      ]
    },
  ]

  tags = merge(local.tags, { (local.karpenter.discovery_key) = local.karpenter.discovery_value })
}

resource "kubectl_manifest" "cluster_role_dashboard" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "eks-console-dashboard-full-access"
    }
    rules = [
      {
        apiGroups = ["", ]
        resources = ["nodes", "namespaces", "pods",
        ]
        verbs = ["get", "list", ]
      },
      {
        apiGroups = ["apps", ]
        resources = [
          "deployments",
          "daemonsets",
          "statefulsets",
          "replicasets",
        ]
        verbs = ["get", "list", ]
      },
      {
        apiGroups = ["batch", ]
        resources = ["jobs", ]
        verbs     = ["get", "list", ]
      },
    ]
  })
}

resource "kubectl_manifest" "cluster_role_binding_dashboard" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "eks-console-dashboard-full-access"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "eks-console-dashboard-full-access"
    }
    subjects = [
      {
        apiGroup = "rbac.authorization.k8s.io"
        kind     = "Group"
        name     = "eks-console-dashboard-full-access"
      },
    ]
  })

  depends_on = [kubectl_manifest.cluster_role_dashboard, ]
}

resource "kubectl_manifest" "cluster_role_binding_engineers_edit" {
  yaml_body = yamlencode({
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "engineers-edit"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "edit"
    }
    subjects = [
      {
        apiGroup = "rbac.authorization.k8s.io"
        kind     = "Group"
        name     = "engineers"
      },
    ]
  })
}
