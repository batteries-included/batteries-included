defmodule CommonCore.Batteries.KialiConfig do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.kiali_image()
    field :version, :string, default: Defaults.Monitoring.kiali_version()
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [:image, :version])
  end
end
