defmodule CommonCore.Batteries.PostgresOperatorConfig do
  use TypedEctoSchema
  import Ecto.Changeset

  alias CommonCore.Defaults

  @primary_key false
  @derive Jason.Encoder
  typed_embedded_schema do
    field :image, :string, default: Defaults.Images.postgres_operator_image()
    field :spilo_image, :string, default: Defaults.Images.spilo_image()
    field :bouncer_image, :string, default: Defaults.Images.postgres_bouncer_image()

    field :logical_backup_image, :string, default: Defaults.Images.postgres_logical_backup_image()

    field :json_logging_enabled, :boolean, default: true
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [
      :image,
      :spilo_image,
      :bouncer_image,
      :logical_backup_image,
      :json_logging_enabled
    ])
  end
end
