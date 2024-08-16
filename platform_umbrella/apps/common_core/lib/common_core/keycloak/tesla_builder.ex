defmodule CommonCore.Keycloak.TeslaBuilder do
  @moduledoc false
  alias Tesla.Middleware.BaseUrl
  alias Tesla.Middleware.BearerAuth
  alias Tesla.Middleware.FormUrlencoded
  alias Tesla.Middleware.JSON
  alias Tesla.Middleware.Telemetry

  @spec build_client(
          binary,
          nil | binary,
          nil | module() | {module(), Keyword.t()}
        ) :: Tesla.Client.t()
  def build_client(base_url, nil = _token, nil = _adapter), do: Tesla.client(middleware(base_url))

  def build_client(base_url, nil = _token, adapter), do: base_url |> middleware() |> Tesla.client(adapter)

  def build_client(base_url, token, nil = _adapter) do
    Tesla.client(middleware(base_url, token))
  end

  def build_client(base_url, token, adapter) do
    Tesla.client(middleware(base_url, token), adapter)
  end

  @spec middleware(String.t()) :: list(module() | {module(), any()})
  defp middleware(base_url), do: [{BaseUrl, base_url}, FormUrlencoded, JSON, Telemetry]

  @spec middleware(String.t(), String.t()) :: list(module() | {module(), any()})
  defp middleware(base_url, token), do: [{BearerAuth, token: token}, {BaseUrl, base_url}, JSON, Telemetry]
end
