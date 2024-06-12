defmodule CommonCore.JWK do
  @moduledoc """
  JSON Web Key (JWK) utilities.
  """

  defmodule BadKeyError do
    @moduledoc false
    defexception [:message, :exception]

    def exception(opts \\ []) do
      exception = Keyword.get(opts, :exception, nil)

      message = """
      the key and message can not be verified
          #{:error |> Exception.format(exception, []) |> String.replace("\n", "\n    ")}
      """

      %__MODULE__{message: message, exception: exception}
    end
  end

  defimpl Plug.Exception, for: BadKeyError do
    @doc """
    Return a generic not allowed error code.
    """
    def status(_), do: 403

    def actions(_), do: []
  end

  @default_curve "P-256"

  @doc """
  Generate a new JWK in a form usable for embedding into ecto rows in a map field
  """
  def generate_key do
    {:ec, @default_curve}
    |> JOSE.JWK.generate_key()
    |> JOSE.JWK.to_map()
    |> elem(1)
  end
end
