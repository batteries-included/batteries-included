defmodule CommonCore.ET.KnativeReport do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.FromKubeState

  batt_embedded_schema do
    field :pod_counts, :map
  end

  def new(%StateSummary{knative_services: services} = state_summary) do
    pod_counts =
      Map.new(services, fn service ->
        {service.name, num_pods(service, state_summary)}
      end)

    Schema.schema_new(__MODULE__,
      pod_counts: pod_counts
    )
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end

  defp num_pods(service, state_summary) do
    pods = FromKubeState.all_resources(state_summary, :pod)

    Enum.count(pods, fn pod ->
      FieldAccessors.labeled_owner(pod) == service.id
    end)
  end
end
