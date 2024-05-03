defmodule HomeBase do
  @moduledoc """
  HomeBase keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def schema do
    quote do
      use Ecto.Schema

      import CommonCore.Util.EctoValidations
      import Ecto.Changeset
      import Ecto.Query

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime]
    end
  end

  def context do
    quote do
      import Ecto.Query, warn: false

      alias Ecto.Changeset
      alias Ecto.Multi
      alias HomeBase.Repo
    end
  end

  @doc """
  When used, dispatch to the appropriate helper.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
