defmodule CommonCore.ET.NodeReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  import CommonCore.ET.ReportTools
  import CommonCore.Resources.Quantity

  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.FromKubeState

  batt_embedded_schema do
    # node hostname to number of pods running on the node
    field :pod_counts, :map
    # The average number of cores across all nodes
    field :avg_cores, :float
    # The average ammount of memory
    field :avg_mem, :float
  end

  def new(%StateSummary{} = state_summary) do
    nodes = FromKubeState.all_resources(state_summary, :node)

    cpu_count =
      Enum.reduce(nodes, 0.0, fn node, acc ->
        cpu = node |> FieldAccessors.status() |> Map.get("capacity", %{}) |> Map.get("cpu")
        acc + parse_quantity(cpu)
      end)

    memory_count =
      Enum.reduce(nodes, 0.0, fn node, acc ->
        memory = node |> FieldAccessors.status() |> Map.get("capacity", %{}) |> Map.get("memory")
        acc + parse_quantity(memory)
      end)

    pod_counts =
      count_pods_by(state_summary, fn pod ->
        host_ip = pod |> FieldAccessors.status() |> Map.get("hostIP")

        node = find_node(nodes, host_ip)

        if node == nil do
          "unknown"
        else
          FieldAccessors.name(node) || host_ip
        end
      end)

    node_count = length(nodes)

    avg_cores = if node_count > 0, do: cpu_count / node_count, else: 0.0
    avg_mem = if node_count > 0, do: memory_count / node_count, else: 0.0

    Schema.schema_new(__MODULE__,
      pod_counts: pod_counts,
      avg_cores: avg_cores,
      avg_mem: avg_mem
    )
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end

  ## Pods list the host address not the hostname.
  # So this finds the node by the host address
  defp find_node(nodes, host_ip) do
    Enum.find(nodes, fn node ->
      node
      |> FieldAccessors.status()
      |> Map.get("addresses")
      |> Enum.any?(fn addr -> Map.get(addr, "address") == host_ip end)
    end)
  end
end
