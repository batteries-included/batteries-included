defmodule CommonCore.ResouceFactory do
  @moduledoc false
  use ExMachina

  alias CommonCore.Resources.Builder, as: B

  def pod_factory do
    namespace = sequence(:pod_namespace, ["battery-core", "battery-base", "battery-knative"])
    pod_name = sequence(:pod_name, &"pod-name-#{&1}")

    :pod
    |> B.build_resource()
    |> B.name(pod_name)
    |> B.namespace(namespace)
  end
end
