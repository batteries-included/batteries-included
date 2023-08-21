defmodule KubeServices.Factory do
  @moduledoc false
  use ExMachina

  @container_status_mapping [
    ready: "Ready",
    containers_ready: "ContainersReady",
    initialized: "Initialized",
    pod_has_network: "PodHasNetwork",
    pod_scheduled: "PodScheduled"
  ]

  def get_container_status_mapping, do: @container_status_mapping

  def condition_factory do
    %{"status" => "True", "type" => "Ready"}
  end

  def conditions_factory(attrs) do
    build_conditions(
      @container_status_mapping,
      attrs[:condition] || :ready,
      []
    )
  end

  defp build_conditions(condition_mapping, search_condition, acc, found \\ false)

  defp build_conditions([{condition, name} | tail], search, acc, found) do
    # if this is the condition OR we've found it earlier, keep writing True statuses
    status = condition == search || found

    new =
      :condition
      |> build()
      |> with_type(name)
      |> with_status(if status, do: "True", else: "False")

    build_conditions(tail, search, [new | acc], status)
  end

  defp build_conditions([], _search, acc, _found), do: acc

  def status_factory do
    %{
      "phase" => "Running",
      "qosClass" => "Burstable",
      "conditions" => build(:conditions)
    }
  end

  def metadata_factory do
    %{"name" => sequence("name"), "namespace" => sequence("namespace")}
  end

  def spec_factory do
    %{}
  end

  def pod_factory do
    %{
      "metadata" => build(:metadata),
      "spec" => build(:spec),
      "status" => build(:status)
    }
  end

  def with_type(condition, type), do: %{condition | "type" => type}

  def with_false_condition(conditions, type),
    do:
      Enum.map(conditions, fn
        %{"type" => ^type} = c -> Map.put(c, "status", "False")
        c -> c
      end)

  def with_true_condition(conditions, type),
    do:
      Enum.map(conditions, fn
        %{"type" => ^type} = c -> Map.put(c, "status", "True")
        c -> c
      end)

  def with_conditions(%{"conditions" => _} = status, conditions), do: %{status | "conditions" => conditions}

  def with_conditions(%{"status" => %{"conditions" => _} = status} = pod, conditions),
    do: %{pod | "status" => Map.put(status, "conditions", conditions)}

  def with_status(%{"status" => _, "type" => _} = condition, status), do: %{condition | "status" => status}

  def with_status(%{"status" => _} = pod, status), do: %{pod | "status" => status}

  def with_name(%{"name" => _} = metadata, name), do: %{metadata | "name" => name}

  def with_name(%{"metadata" => %{} = metadata} = pod, name), do: %{pod | "metadata" => with_name(metadata, name)}

  def with_namespace(%{"namespace" => _} = metadata, namespace), do: %{metadata | "namespace" => namespace}

  def with_namespace(%{"metadata" => %{} = metadata} = pod, namespace),
    do: %{pod | "metadata" => with_namespace(metadata, namespace)}
end
