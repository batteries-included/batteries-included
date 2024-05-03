defmodule CommonCore do
  @moduledoc """
  Schemas and other code that needs to be used
  without database access sometimes.
  """

  def schema(opts) do
    # TypedSchema errors when encoding a struct with associations
    # that have not been loaded. To prevent that, pass through
    # they keys of the unloaded assocations like so:
    #
    #     use CommonCore, {:schema, no_encode: [:field_name]}
    #
    no_encode = Keyword.get(opts, :no_encode, [])

    quote do
      unquote(schema_helpers())

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]

      @derive {Jason.Encoder, except: [:__meta__] ++ unquote(no_encode)}
    end
  end

  def embedded_schema(_opts) do
    quote do
      unquote(schema_helpers())

      @primary_key false

      @derive Jason.Encoder
    end
  end

  defp schema_helpers do
    quote do
      use TypedEctoSchema

      import Ecto.Changeset
      import Ecto.Query
    end
  end

  @doc """
  When used, dispatch to the appropriate helper.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [[]])
  end

  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end
end
