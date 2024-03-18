defmodule ControlServer.Projects.Project do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  @timestamps_opts [type: :utc_datetime_usec]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "projects" do
    field :name, :string
    field :type, Ecto.Enum, values: [:web, :ml, :database]
    field :description, :string

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :type, :description])
    |> validate_required([:name, :type])
    |> validate_length(:description, max: 1000)
  end

  def type_options_for_select do
    __MODULE__
    |> Ecto.Enum.values(:type)
    |> Enum.map(&{type_name(&1), &1})
  end

  def type_name(:web), do: "Web"
  def type_name(:ml), do: "Machine Learning"
  def type_name(:database), do: "Database Only"
  def type_name(type), do: Atom.to_string(type)
end
