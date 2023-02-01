defmodule CommonCore.OryKratosAdminClient do
  use Tesla

  require Logger

  plug(Tesla.Middleware.JSON)

  def list_identities(base_url), do: do_get("#{base_url}/admin/identities")

  def get_identity(base_url, id), do: do_get("#{base_url}/admin/identities/#{id}")

  defp do_get(url) do
    case get(url) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:error, exception} -> {:error, exception}
      err -> {:error, {:unknown_error, err}}
    end
  end
end
