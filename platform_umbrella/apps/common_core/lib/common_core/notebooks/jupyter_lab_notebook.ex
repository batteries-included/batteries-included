defmodule CommonCore.Notebooks.JupyterLabNotebook do
  @moduledoc false
  use TypedEctoSchema

  import Ecto.Changeset

  require Logger

  @timestamps_opts [type: :utc_datetime_usec]
  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  typed_schema "jupyter_lab_notebooks" do
    field :image, :string, default: "jupyter/datascience-notebook:lab-4.0.7"
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(jupyter_lab_notebook, attrs) do
    jupyter_lab_notebook
    |> cast(attrs, [:name, :image])
    |> add_name()
    |> validate_required([:name, :image])
  end

  defp add_name(%Ecto.Changeset{changes: %{name: _}} = c), do: c

  defp add_name(%Ecto.Changeset{data: %{name: nil}} = changeset) do
    put_change(changeset, :name, MnemonicSlugs.generate_slug())
  end

  defp add_name(%Ecto.Changeset{data: %{name: name}} = changeset) when is_bitstring(name), do: changeset

  defp add_name(changeset) do
    put_change(changeset, :name, MnemonicSlugs.generate_slug())
  end
end
