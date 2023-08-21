defmodule CommonCore.Keycloak.TeslaBuilder do
  @moduledoc false
  @spec build_client(
          binary,
          nil | binary,
          nil | module() | {module(), Keyword.t()}
        ) :: Tesla.Client.t()
  def build_client(base_url, nil = _token, nil = _adapter), do: Tesla.client(middleware(base_url))

  def build_client(base_url, nil = _token, adapter), do: Tesla.client(middleware(base_url), adapter)

  def build_client(base_url, token, nil = _adapter) do
    Tesla.client(middleware(base_url, token))
  end

  def build_client(base_url, token, adapter) do
    Tesla.client(middleware(base_url, token), adapter)
  end

  @spec middleware(String.t()) :: list(module() | {module(), any()})
  defp middleware(base_url),
    do: [{Tesla.Middleware.BaseUrl, base_url}, Tesla.Middleware.FormUrlencoded, Tesla.Middleware.JSON]

  @spec middleware(String.t(), String.t()) :: list(module() | {module(), any()})
  defp middleware(base_url, token) do
    [
      {Tesla.Middleware.BearerAuth, token: token},
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON
    ]
  end
end
