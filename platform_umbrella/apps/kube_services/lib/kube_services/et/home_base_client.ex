defmodule KubeServices.ET.HomeBaseClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ET.HostReport
  alias CommonCore.ET.UsageReport
  alias CommonCore.StateSummary

  require Logger

  typedstruct module: State do
    field :home_url, String.t()
    field :http_client, Tesla.Client.t(), default: nil
    field :control_jwk, JOSE.JWK.t(), default: nil
    field :usage_report_path, String.t(), default: nil
    field :host_report_path, String.t(), default: nil
  end

  @me __MODULE__
  @state_opts ~w(home_url)a

  def send_usage(client \\ @me, state_summary) do
    GenServer.call(client, {:send_usage, state_summary})
  end

  def send_hosts(client \\ @me, state_summary) do
    GenServer.call(client, {:send_hosts, state_summary})
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

    state = struct!(State, home_url: home_url, http_client: nil, control_jwk: control_jwk)
    build_client(state)
  end

  @impl GenServer
  def handle_info(%StateSummary{} = state_summary, state) do
    Logger.debug("Received state summary getting new control jwk")
    # For now we don't
    {:noreply,
     %State{
       state
       | control_jwk: CommonCore.StateSummary.JWK.jwk(state_summary),
         usage_report_path: CommonCore.ET.URLs.usage_report_path(state_summary),
         host_report_path: CommonCore.ET.URLs.host_reports_path(state_summary)
     }}
  end

  @impl GenServer
  def handle_call({:send_usage, state_summary}, _, state) do
    Logger.info("Sending usage to #{state.home_url}")
    {:reply, do_send_usage(state, state_summary), state}
  end

  @impl GenServer
  def handle_call({:send_hosts, state_summary}, _, state) do
    Logger.info("Sending hosts to #{state.home_url}")
    {:reply, do_send_host(state, state_summary), state}
  end

  defp build_client(%State{home_url: home_url, http_client: nil} = state) do
    client = Tesla.client(middleware(home_url))
    {:ok, %State{state | http_client: client}}
  end

  defp middleware(base_url) do
    [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON
    ]
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
    jwk |> JOSE.JWT.sign(JOSE.JWT.from(data)) |> elem(1)
  end
end
