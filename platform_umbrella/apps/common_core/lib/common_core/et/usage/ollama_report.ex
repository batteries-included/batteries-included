defmodule CommonCore.ET.OllamaReport do
  @moduledoc false

  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.StateSummary

  batt_embedded_schema do
    field :model_counts, :map
    field :instance_counts, :map
  end

  def new(%StateSummary{model_instances: model_instances} = _state_summary) do
    model_counts =
      model_instances
      |> Enum.map(fn instance -> instance.model end)
      |> Enum.group_by(& &1)
      |> Map.new(fn {model, instances} -> {model, Enum.count(instances)} end)

    instance_counts =
      Map.new(model_instances, fn instance ->
        {instance.model, instance.num_instances}
      end)

    Schema.schema_new(__MODULE__,
      model_counts: model_counts,
      instance_counts: instance_counts
    )
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end
end
