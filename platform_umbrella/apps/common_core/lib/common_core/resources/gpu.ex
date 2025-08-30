defmodule CommonCore.Resources.GPU do
  @moduledoc false
  alias CommonCore.Nvidia.GPU
  alias CommonCore.StateSummary.Core

  @node_types_with_gpus GPU.with_gpus()

  def maybe_add_gpu_resource(template, %{node_type: type} = _resource) when type in @node_types_with_gpus,
    do: put_in(template, ["spec", "containers", Access.all(), "resources"], %{"limits" => %{"nvidia.com/gpu" => 1}})

  def maybe_add_gpu_resource(template, _resource), do: template

  def maybe_add_node_selector(template, %{node_type: :any_nvidia} = _resource, state) do
    if kind_nvidia_install?(state) do
      # For kind clusters with nvidia device plugin, don't add node selector
      # The device plugin and GPU labels should be enough for scheduling
      template
    else
      # Assume this is karpenter
      put_in(template, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-gpu"})
    end
  end

  def maybe_add_node_selector(template, %{node_type: :nvidia_a10} = _resource, _state),
    do: put_in(template, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-a10-gpu"})

  def maybe_add_node_selector(template, %{node_type: :nvidia_a100} = _resource, _state),
    do: put_in(template, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-a100-gpu"})

  def maybe_add_node_selector(template, %{node_type: :nvidia_h100} = _resource, _state),
    do: put_in(template, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-h100-gpu"})

  def maybe_add_node_selector(template, %{node_type: :nvidia_h200} = _resource, _state),
    do: put_in(template, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-h200-gpu"})

  def maybe_add_node_selector(template, _resource, _state), do: template

  def maybe_add_tolerations(k8s_resource, %{node_type: type} = _resource) when type in @node_types_with_gpus,
    do: put_in(k8s_resource, ["spec", "tolerations"], [%{"key" => "nvidia.com/gpu", "operator" => "Exists"}])

  def maybe_add_tolerations(template, _resource), do: template

  def maybe_add_nvidia_runtime(template, state) do
    if kind_nvidia_install?(state) do
      update_in(template, ["spec"], fn spec ->
        Map.put(spec || %{}, "runtimeClassName", "nvidia")
      end)
    else
      template
    end
  end

  defp kind_nvidia_install?(state) do
    Core.kind_cluster?(state) &&
      CommonCore.StateSummary.Batteries.batteries_installed?(state, :nvidia_device_plugin)
  end

  def nvidia_gpu_affinity do
    %{
      "nodeAffinity" => %{
        "requiredDuringSchedulingIgnoredDuringExecution" => %{
          "nodeSelectorTerms" => [
            %{
              "matchExpressions" => [
                %{
                  "key" => "feature.node.kubernetes.io/pci-10de.present",
                  "operator" => "In",
                  "values" => ["true"]
                }
              ]
            },
            %{
              "matchExpressions" => [
                %{
                  "key" => "feature.node.kubernetes.io/cpu-model.vendor_id",
                  "operator" => "In",
                  "values" => ["NVIDIA"]
                }
              ]
            },
            %{
              "matchExpressions" => [
                %{"key" => "nvidia.com/gpu.present", "operator" => "In", "values" => ["true"]}
              ]
            }
          ]
        }
      }
    }
  end
end
