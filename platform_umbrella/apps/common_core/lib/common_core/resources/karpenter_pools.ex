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

    spec = %{
      "amiFamily" => "AL2",
      "amiSelectorTerms" => [%{"alias" => battery.config.ami_alias}],
      "role" => battery.config.node_role_name,
      "securityGroupSelectorTerms" => [%{"tags" => %{"karpenter.sh/discovery" => cluster_name}}],
      "subnetSelectorTerms" => [%{"tags" => %{"karpenter.sh/discovery" => cluster_name}}],
      "tags" => %{
        "karpenter.sh/discovery" => cluster_name,
        "batteriesincl.com/managed" => "true",
        "batteriesincl.com/environment" => "organization/bi/#{cluster_name}",
        "Name" => "#{cluster_name}-fleet"
      }
    }

    :karpenter_ec2node_class
    |> B.build_resource()
    |> B.name("default")
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
    spec = %{
      "disruption" => %{"consolidateAfter" => "30s", "consolidationPolicy" => "WhenEmpty"},
      "limits" => %{"cpu" => 1000},
      "template" => %{
        "spec" => %{
          "nodeClassRef" => %{"name" => "default", "group" => "karpenter.k8s.aws", "kind" => "EC2NodeClass"},
          "requirements" => [
            %{"key" => "kubernetes.io/arch", "operator" => "In", "values" => ["amd64"]},
            %{"key" => "karpenter.sh/capacity-type", "operator" => "In", "values" => ["spot", "on-demand"]},
            %{
              "key" => "karpenter.k8s.aws/instance-family",
              "operator" => "In",
              "values" => ["p5", "p4", "g6e", "g6", "g5"]
            },
            %{"key" => "karpenter.k8s.aws/instance-hypervisor", "operator" => "In", "values" => ["nitro"]}
          ],
          "taints" => [%{"key" => "nvidia.com/gpu", "value" => "true", "effect" => "NoSchedule"}]
        }
      }
    }

    :karpenter_node_pool
    |> B.build_resource()
    |> B.name("nvidia-gpu")
    |> B.spec(spec)
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
end
