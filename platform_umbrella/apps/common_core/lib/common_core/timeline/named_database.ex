defmodule CommonCore.Timeline.NamedDatabase do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  @primary_key false
  typed_embedded_schema do
    # WAIT!
    # If you are changing here then change in EventCenter.Database
    field :action, Ecto.Enum, values: [:insert, :update, :delete, :multi]

    # WAIT!
    # If you are changing here then change in EventCenter.Database
    field(:type, Ecto.Enum,
      values: [
        :jupyter_notebook,
        :knative_service,
        :postgres_cluster,
        :redis_cluster,
        :system_battery,
        :timeline_event
      ]
    )

    field :name, :string
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:action, :type, :name])
    |> validate_required([:action, :type])
  end
end
