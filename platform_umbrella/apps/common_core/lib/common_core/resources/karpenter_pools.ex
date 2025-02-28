defmodule CommonCore.Resources.KarpenterPools do
  @moduledoc false
  use CommonCore.IncludeResource,
    ec2nodeclasses_karpenter_k8s_aws: "priv/manifests/karpenter/ec2nodeclasses_karpenter_k8s_aws.yaml",
    nodeclaims_karpenter_sh: "priv/manifests/karpenter/nodeclaims_karpenter_sh.yaml",
    nodepools_karpenter_sh: "priv/manifests/karpenter/nodepools_karpenter_sh.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "karpenter_pools"

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Core

  resource(:crd_ec2nodeclasses_karpenter_k8s_aws) do
    YamlElixir.read_all_from_string!(get_resource(:ec2nodeclasses_karpenter_k8s_aws))
  end

  resource(:crd_nodeclaims_karpenter_sh) do
    YamlElixir.read_all_from_string!(get_resource(:nodeclaims_karpenter_sh))
  end

  resource(:crd_nodepools_karpenter_sh) do
    YamlElixir.read_all_from_string!(get_resource(:nodepools_karpenter_sh))
  end

  resource(:defalt_node_class, battery, state) do
    cluster_name = Core.config_field(state, :cluster_name)

    spec = build_nodeclass_spec("AL2", battery.config.ami_alias, battery.config.node_role_name, cluster_name)

    :karpenter_ec2node_class
    |> B.build_resource()
    |> B.name("default")
    |> B.spec(spec)
  end

  resource(:bottlerocket_node_class, battery, state) do
    cluster_name = Core.config_field(state, :cluster_name)

    spec =
      build_nodeclass_spec(
        "Bottlerocket",
        battery.config.bottlerocket_ami_alias,
        battery.config.node_role_name,
        cluster_name
      )

    :karpenter_ec2node_class
    |> B.build_resource()
    |> B.name("bottlerocket")
    |> B.spec(spec)
  end

  resource(:default_node_pool) do
    spec = %{
      "disruption" => %{"consolidateAfter" => "30s", "consolidationPolicy" => "WhenEmpty"},
      "limits" => %{"cpu" => 1000},
      "template" => %{
        "spec" => %{
          "nodeClassRef" => %{"name" => "default", "group" => "karpenter.k8s.aws", "kind" => "EC2NodeClass"},
          "requirements" => [
            %{"key" => "kubernetes.io/arch", "operator" => "In", "values" => ["amd64"]},
            %{"key" => "karpenter.sh/capacity-type", "operator" => "In", "values" => ["spot", "on-demand"]},
            %{"key" => "karpenter.k8s.aws/instance-family", "operator" => "In", "values" => ["t3", "t3a", "m7a", "m7i"]},
            %{
              "key" => "karpenter.k8s.aws/instance-size",
              "operator" => "In",
              # TODO(jdt): base this list on the default cluster size?
              "values" => [
                "small",
                "medium",
                "large",
                "xlarge",
                "2xlarge",
                "4xlarge",
                "8xlarge",
                "12xlarge",
                "16xlarge",
                "24xlarge",
                "32xlarge",
                "48xlarge"
              ]
            },
            %{"key" => "karpenter.k8s.aws/instance-hypervisor", "operator" => "In", "values" => ["nitro"]}
          ]
        }
      }
    }

    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("default")
    |> B.spec(spec)
  end

  resource(:nvidia_gpu_node_pool) do
    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("nvidia-gpu")
    |> B.spec(build_nvidia_pool_spec(["p5", "p4", "g6e", "g6", "g5"]))
  end

  resource(:nvidia_h100_gpu_node_pool) do
    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("nvidia-h100-gpu")
    |> B.spec(build_nvidia_pool_spec(["p5"]))
  end

  resource(:nvidia_h200_gpu_node_pool) do
    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("nvidia-h200-gpu")
    |> B.spec(build_nvidia_pool_spec(["p5e", "p5en"]))
  end

  resource(:nvidia_a100_gpu_node_pool) do
    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("nvidia-a100-gpu")
    |> B.spec(build_nvidia_pool_spec(["p4", "p4d", "p4de"]))
  end

  resource(:nvidia_a10_gpu_node_pool) do
    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("nvidia-a10-gpu")
    |> B.spec(build_nvidia_pool_spec(["g5"]))
  end

  defp build_nvidia_pool_spec(instance_types) do
    %{
      "disruption" => %{"consolidateAfter" => "30s", "consolidationPolicy" => "WhenEmpty"},
      "limits" => %{"cpu" => 1000},
      "template" => %{
        "spec" => %{
          "nodeClassRef" => %{"name" => "bottlerocket", "group" => "karpenter.k8s.aws", "kind" => "EC2NodeClass"},
          "requirements" => [
            %{"key" => "kubernetes.io/arch", "operator" => "In", "values" => ["amd64"]},
            %{"key" => "karpenter.sh/capacity-type", "operator" => "In", "values" => ["spot", "on-demand"]},
            %{
              "key" => "karpenter.k8s.aws/instance-family",
              "operator" => "In",
              "values" => instance_types
            },
            %{"key" => "karpenter.k8s.aws/instance-hypervisor", "operator" => "In", "values" => ["nitro"]}
          ],
          "taints" => [%{"key" => "nvidia.com/gpu", "value" => "true", "effect" => "NoSchedule"}]
        }
      }
    }
  end

  resource(:amd_gpu_node_pool) do
    spec = %{
      "disruption" => %{"consolidateAfter" => "30s", "consolidationPolicy" => "WhenEmpty"},
      "limits" => %{"cpu" => 1000},
      "template" => %{
        "spec" => %{
          "nodeClassRef" => %{"name" => "default", "group" => "karpenter.k8s.aws", "kind" => "EC2NodeClass"},
          "requirements" => [
            %{"key" => "kubernetes.io/arch", "operator" => "In", "values" => ["amd64"]},
            %{"key" => "karpenter.sh/capacity-type", "operator" => "In", "values" => ["spot", "on-demand"]},
            %{"key" => "karpenter.k8s.aws/instance-family", "operator" => "In", "values" => ["g4ad"]},
            %{"key" => "karpenter.k8s.aws/instance-hypervisor", "operator" => "In", "values" => ["nitro"]}
          ],
          "taints" => [%{"key" => "amd.com/gpu", "value" => "true", "effect" => "NoSchedule"}]
        }
      }
    }

    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("amd-gpu")
    |> B.spec(spec)
  end

  defp build_nodeclass_spec(family, alias, role, cluster_name) do
    %{
      "amiFamily" => family,
      "amiSelectorTerms" => [%{"alias" => alias}],
      "role" => role,
      "securityGroupSelectorTerms" => [%{"tags" => %{"karpenter.sh/discovery" => cluster_name}}],
      "subnetSelectorTerms" => [%{"tags" => %{"karpenter.sh/discovery" => cluster_name}}],
      # allow containers to access the AWS metadata service
      # necessary for e.g. aws-load-balancer-controller to run on karpenter nodes
      # this also matches how we configure the bootstrap nodes
      "metadataOptions" => %{"httpPutResponseHopLimit" => 2},
      "tags" => %{
        "karpenter.sh/discovery" => cluster_name,
        "batteriesincl.com/managed" => "true",
        "batteriesincl.com/environment" => "organization/bi/#{cluster_name}",
        "Name" => "#{cluster_name}-fleet"
      }
    }
  end
end
