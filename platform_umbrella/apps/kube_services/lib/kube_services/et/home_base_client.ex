defmodule KubeServices.ET.HomeBaseClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ET.HostReport
  alias CommonCore.ET.InstallStatus
  alias CommonCore.ET.UsageReport
  alias CommonCore.StateSummary

  require Logger

  defmodule State do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      field :home_url, :string
      field :http_client, :map, default: nil
      field :control_jwk, :map, default: nil
      field :usage_report_path, :string, default: nil
      field :host_report_path, :string, default: nil
      field :status_path, :string, default: nil
    end
  end

  @me __MODULE__
  @state_opts ~w(home_url)a

  def send_usage(client \\ @me, state_summary) do
    GenServer.call(client, {:send_usage, state_summary})
  end

  def send_hosts(client \\ @me, state_summary) do
    GenServer.call(client, {:send_hosts, state_summary})
  end

  @spec get_status(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: {:ok, InstallStatus.t()} | {:error, any()}
  def get_status(client \\ @me) do
    GenServer.call(client, :get_status)
  end

  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  @impl GenServer
  def init(opts) do
    # Get the default url we'll need that to create the http client
    home_url = Keyword.fetch!(opts, :home_url)

    :ok = EventCenter.SystemStateSummary.subscribe()

    control_jwk =
      Keyword.get_lazy(opts, :control_jwk, fn ->
        state_summary = KubeServices.SystemState.Summarizer.cached()
        CommonCore.StateSummary.JWK.jwk(state_summary)
      end)

    status_path =
      Keyword.get_lazy(opts, :status_path, fn ->
        state_summary = KubeServices.SystemState.Summarizer.cached()
        CommonCore.ET.URLs.status_path(state_summary)
      end)

    state =
      State.new!(
        home_url: home_url,
        http_client: nil,
        control_jwk: control_jwk,
        status_path: status_path
      )

    {:ok, build_client(state)}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = state_summary, state) do
    {:noreply,
     %State{
       state
       | control_jwk: CommonCore.StateSummary.JWK.jwk(state_summary),
         usage_report_path: CommonCore.ET.URLs.usage_report_path(state_summary),
         host_report_path: CommonCore.ET.URLs.host_reports_path(state_summary),
         status_path: CommonCore.ET.URLs.status_path(state_summary)
     }}
  end

  @impl GenServer
  def handle_call({:send_usage, state_summary}, _, state) do
    Logger.info("Sending usage to #{state.home_url}")
    {:reply, do_send_usage(state, state_summary), state}
  end

  def handle_call({:send_hosts, state_summary}, _, state) do
    Logger.info("Sending hosts to #{state.home_url}")
    {:reply, do_send_host(state, state_summary), state}
  end

  def handle_call(:get_status, _from, state) do
    {:reply, do_get_status(state), state}
  end

  defp build_client(%State{home_url: home_url, http_client: nil} = state) do
    client = Tesla.client(middleware(home_url))
    %State{state | http_client: client}
  end

  defp middleware(base_url) do
    [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON
    ]
  end

  defp do_get_status(%State{http_client: client, status_path: status_path} = _state) do
    Logger.debug("Getting status")

    with {:ok, %{body: %{"jwt" => jwt}} = _env} <- Tesla.get(client, status_path),
         {:ok, verified_resp} <- CommonCore.JWK.verify(jwt),
         {:ok, %{} = status} <- InstallStatus.new(verified_resp) do
      {:ok, status}
    else
      {:error, reason} ->
        Logger.error("Failed to get status: #{inspect(reason)}")
        {:error, reason}

      unexpected ->
        Logger.error("Unexpected response from home")
        {:error, {:unexpected_response, unexpected}}
    end
  end

  defp do_send_usage(%{http_client: client, usage_report_path: usage_report_path} = state, state_summary) do
    with {:ok, usage_report} <- UsageReport.new(state_summary),
         {:ok, _} <- Tesla.post(client, usage_report_path, %{jwt: sign(state, usage_report)}) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to send usage report: #{inspect(reason)}")
        {:error, reason}

      unexpected ->
        Logger.error("Unexpected response from home: #{inspect(unexpected)}")
        {:error, {:unexpected_response, unexpected}}
    end
  end

  defp do_send_host(%State{http_client: client, host_report_path: host_report_path} = state, state_summary) do
    with {:ok, report} <- HostReport.new(state_summary),
         {:ok, _} <- Tesla.post(client, host_report_path, %{jwt: sign(state, report)}) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to send host report: #{inspect(reason)}")
        {:error, reason}

      unexpected ->
        Logger.error("Unexpected response from home: #{inspect(unexpected)}")
        {:error, {:unexpected_response, unexpected}}
    end
  end

  defp sign(%State{control_jwk: jwk}, data) do
    jwk |> JOSE.JWT.sign(data) |> elem(1)
  end
end
