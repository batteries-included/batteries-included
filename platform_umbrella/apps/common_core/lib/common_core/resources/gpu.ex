defmodule CommonCore.Resources.GPU do
  @moduledoc false
  alias CommonCore.Defaults.GPU

  @node_types_with_gpus GPU.node_types_with_gpus()

  def maybe_add_gpu_resource(k8s_resource, %{node_type: type} = _resource) when type in @node_types_with_gpus,
    do: put_in(k8s_resource, ["spec", "containers", Access.all(), "resources"], %{"limits" => %{"nvidia.com/gpu" => 1}})

  def maybe_add_gpu_resource(k8s_resource, _resource), do: k8s_resource

  def maybe_add_node_selector(k8s_resource, %{node_type: :any_nvidia} = _resource),
    do: put_in(k8s_resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-gpu"})

  def maybe_add_node_selector(k8s_resource, %{node_type: :nvidia_a10} = _resource),
    do: put_in(k8s_resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-a10-gpu"})

  def maybe_add_node_selector(k8s_resource, %{node_type: :nvidia_a100} = _resource),
    do: put_in(k8s_resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-a100-gpu"})

  def maybe_add_node_selector(k8s_resource, %{node_type: :nvidia_h100} = _resource),
    do: put_in(k8s_resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-h100-gpu"})

  def maybe_add_node_selector(k8s_resource, %{node_type: :nvidia_h200} = _resource),
    do: put_in(k8s_resource, ["spec", "nodeSelector"], %{"karpenter.sh/nodepool" => "nvidia-h200-gpu"})

  def maybe_add_node_selector(k8s_resource, _resource), do: k8s_resource

  def maybe_add_tolerations(k8s_resource, %{node_type: type} = _resource) when type in @node_types_with_gpus,
    do: put_in(k8s_resource, ["spec", "tolerations"], [%{"key" => "nvidia.com/gpu", "operator" => "Exists"}])

  def maybe_add_tolerations(k8s_resource, _resource), do: k8s_resource
end
