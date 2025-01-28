defmodule CommonCore.ET.TraditionalServicesReport do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.StateSummary

  batt_embedded_schema do
    field :instance_counts, :map
  end

  def new(%StateSummary{traditional_services: services} = _state_summary) do
    instance_counts =
      Map.new(services, fn service ->
        {service.name, service.num_instances}
      end)

    Schema.schema_new(__MODULE__, instance_counts: instance_counts)
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end
end
