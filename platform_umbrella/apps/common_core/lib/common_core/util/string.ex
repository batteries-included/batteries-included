defmodule CommonCore.Util.String do
  @moduledoc false

  @doc """
  Checks whether arg is nil or equal to the empty string
  """
  defguard is_empty(arg) when is_nil(arg) or arg == ""
end
