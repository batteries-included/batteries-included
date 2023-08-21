defmodule ControlServer.Projects.SystemProject do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @possible_types [
    :web,
    :ml,
    :database
  ]
  def possible_types, do: @possible_types

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "system_projects" do
    field :description, :string
    field :name, :string
    field :type, Ecto.Enum, values: @possible_types

    timestamps()
  end

  @doc false
  def changeset(system_project, attrs) do
    system_project
    |> cast(attrs, [:name, :type, :description])
    |> validate_required([:name, :type])
  end
end
