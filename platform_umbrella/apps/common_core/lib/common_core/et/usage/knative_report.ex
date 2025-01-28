defmodule CommonCore.ET.KnativeReport do
  @moduledoc false

  use CommonCore, :embedded_schema

  import CommonCore.ET.ReportTools

  alias CommonCore.Ecto.Schema
  alias CommonCore.Resources.FieldAccessors
  alias CommonCore.StateSummary

  batt_embedded_schema do
    field :pod_counts, :map
  end

  def new(%StateSummary{knative_services: services} = state_summary) do
    # compute the pod count by owner (batt ID) once and pass that around
    pods_by_owner = count_pods_by(state_summary, &FieldAccessors.labeled_owner/1)

    pod_counts =
      Map.new(services, &count_by_service(&1, pods_by_owner))

    Schema.schema_new(__MODULE__, pod_counts: pod_counts)
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end

  # create a tuple of service name to pod count using the pre-computed map
  defp count_by_service(service, pods_by_owner), do: {service.name, Map.get(pods_by_owner, service.id, 0)}
end
