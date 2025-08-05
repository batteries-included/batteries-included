defmodule CommonCore.Util.String do
  @moduledoc false

  @doc """
  Checks whether arg is nil or equal to the empty string
  """
  defguard is_empty(arg) when is_nil(arg) or arg == ""

  @spec kebab_case(atom()) :: String.t()
  def kebab_case(a) when is_atom(a), do: kebab_case(Atom.to_string(a))

  @spec kebab_case(String.t()) :: String.t()
  def kebab_case(s) do
    s
    |> String.downcase()
    |> String.replace(" ", "-")
    |> String.replace("_", "-")
  end
end
