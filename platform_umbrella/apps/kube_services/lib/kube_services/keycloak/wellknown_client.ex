defmodule KubeServices.Keycloak.WellknownClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  import CommonCore.Util.Tesla

  alias CommonCore.OpenAPI.OIDC.OIDCConfiguration
  alias CommonCore.StateSummary.URLs
  alias KubeServices.SystemState.Summarizer

  require Logger

  typedstruct module: State do
    field :base_url, String.t()

    def to_client(%{base_url: base_url}) do
      Tesla.client([
        {Tesla.Middleware.BaseUrl, base_url},
        {Tesla.Middleware.Timeout, timeout: 2_000},
        Tesla.Middleware.Compression,
        Tesla.Middleware.JSON,
        Tesla.Middleware.Telemetry
      ])
    end
  end

  @state_opts ~w(base_url)a
  @me __MODULE__

  def start_link(opts) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.put_new_lazy(:base_url, fn ->
        Summarizer.cached()
        |> URLs.uri_for_battery(:keycloak)
        |> URI.to_string()
      end)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(opts) do
    state = struct!(State, opts)
    Logger.info("Starting KubeServices.Keycloak.WellknownClient with base_url = #{state.base_url}")
    {:ok, state}
  end

  def base_url(target \\ @me), do: GenServer.call(target, :base_url)

  @spec get(GenServer.server(), String.t()) :: {:ok, OIDCConfiguration.t()} | {:error, any()}
  def get(target \\ @me, realm) do
    GenServer.call(target, {:get, realm})
  end

  def handle_call(:base_url, _from, state) do
    {:reply, state.base_url, state}
  end

  def handle_call({:get, realm}, _from, state) do
    {:reply,
     state
     |> State.to_client()
     |> Tesla.get("/realms/#{realm}/.well-known/openid-configuration")
     |> to_result(&OIDCConfiguration.new!/1), state}
  end
end
