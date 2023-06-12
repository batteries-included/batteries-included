defmodule CommonCore.Keycloak.TeslaBuilder do
  @type adapter_spec :: module() | {module(), Keyword.t()} | nil

  @spec build_client(String.t(), adapter_spec()) :: Tesla.Client.t()
  def build_client(base_url, nil), do: Tesla.client(middleware(base_url))
  def build_client(base_url, adapter), do: Tesla.client(middleware(base_url), adapter)

  @spec build_client(binary, binary, adapter_spec()) :: Tesla.Client.t()
  def build_client(base_url, token, nil) do
    Tesla.client(middleware(base_url, token))
  end

  def build_client(base_url, token, adapter) do
    Tesla.client(middleware(base_url, token), adapter)
  end

  @spec middleware(String.t()) :: list(module() | {module(), any()})
  defp middleware(base_url),
    do: [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.FormUrlencoded,
      Tesla.Middleware.JSON
    ]

  @spec middleware(String.t(), String.t()) :: list(module() | {module(), any()})
  defp middleware(base_url, token),
    do: [{Tesla.Middleware.BearerAuth, token: token} | middleware(base_url)]
end
