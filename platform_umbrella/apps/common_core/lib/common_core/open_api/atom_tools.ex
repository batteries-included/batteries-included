defmodule CommonCore.OpenApi.AtomTools do
  def maybe_exiting_atom(string) do
    try do
      {:ok, String.to_existing_atom(string)}
    rescue
      e -> {:error, e}
    end
  end
end
