defmodule CommonCore.JWK.BadKeyError do
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

  defimpl Plug.Exception, for: __MODULE__ do
    @doc """
    Return a generic not allowed error code.
    """
    def status(_), do: 403

    def actions(_), do: []
  end
end
