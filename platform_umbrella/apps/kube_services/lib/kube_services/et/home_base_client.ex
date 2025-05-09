defmodule KubeServices.ET.HomeBaseClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ET.HostReport
  alias CommonCore.ET.InstallStatus
  alias CommonCore.ET.StableVersionsReport
  alias CommonCore.ET.UsageReport

  require Logger

  defmodule State do
    @moduledoc false
    use CommonCore, :embedded_schema

    batt_embedded_schema do
      # The URL of the home base
      field :home_url, :string

      # The JWK to use to sign requests from this control server
      field :control_jwk, :map
      # The path to send usage reports to
      field :usage_report_path, :string

      # The path to send host reports to
      field :host_report_path, :string
      # Path to get install status
      field :status_path, :string

      # Path to send project snapshots to
      field :project_snapshot_path, :string

      # Path to get stable versions
      field :stable_versions_path, :string

      # The Tesla client to use to make requests
      field :http_client, :map, default: nil
    end
  end

  @me __MODULE__
  @state_opts ~w(home_url control_jwk usage_report_path host_report_path status_path stable_versions_path project_snapshot_path)a

  def send_usage(client \\ @me, state_summary) do
    GenServer.call(client, {:send_usage, state_summary})
  catch
    :exit, {:noproc, _} -> {:error, :not_started}
  end

  def send_hosts(client \\ @me, state_summary) do
    GenServer.call(client, {:send_hosts, state_summary})
  catch
    :exit, {:noproc, _} -> {:error, :not_started}
  end

  @spec get_status(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: {:ok, InstallStatus.t()} | {:error, any()}
  def get_status(client \\ @me) do
    GenServer.call(client, :get_status)
  catch
    :exit, {:noproc, _} -> {:error, :not_started}
  end

  @spec get_stable_versions(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) ::
          {:ok, StableVersionsReport.t()} | {:error, any()}
  def get_stable_versions(client \\ @me) do
    GenServer.call(client, :get_stable_versions)
  catch
    :exit, {:noproc, _} -> {:error, :not_started}
  end

  def export_snapshot(client \\ @me, snapshot) do
    GenServer.call(client, {:export_snapshot, snapshot})
  catch
    :exit, {:noproc, _} -> {:error, :not_started}
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
    control_jwk = Keyword.fetch!(opts, :control_jwk)
    usage_report_path = Keyword.fetch!(opts, :usage_report_path)
    host_report_path = Keyword.fetch!(opts, :host_report_path)
    status_path = Keyword.fetch!(opts, :status_path)
    stable_versions_path = Keyword.fetch!(opts, :stable_versions_path)
    project_snapshot_path = Keyword.fetch!(opts, :project_snapshot_path)

    state =
      State.new!(
        home_url: home_url,
        control_jwk: control_jwk,
        usage_report_path: usage_report_path,
        host_report_path: host_report_path,
        status_path: status_path,
        stable_versions_path: stable_versions_path,
        project_snapshot_path: project_snapshot_path,
        http_client: nil
      )

    Logger.info("Starting HomeBaseClient with home_url: #{home_url}")

    {:ok, build_client(state)}
  end

  @impl GenServer
  def handle_call({:send_usage, state_summary}, _, state) do
    Logger.info("Sending usage to #{state.home_url}")
    {:reply, do_send_usage(state, state_summary), state}
  end

  def handle_call({:send_hosts, state_summary}, _, state) do
    {:reply, do_send_host(state, state_summary), state}
  end

  def handle_call(:get_status, _from, state) do
    {:reply, do_get_status(state), state}
  end

  def handle_call(:get_stable_versions, _from, state) do
    {:reply, do_get_stable_versions(state), state}
  end

  def handle_call({:export_snapshot, snapshot}, _from, state) do
    {
      :reply,
      do_export_snapshot(state, snapshot),
      state
    }
  end

  defp build_client(%State{home_url: home_url, http_client: nil} = state) do
    client = Tesla.client(middleware(home_url))
    %{state | http_client: client}
  end

  defp middleware(base_url) do
    [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON
    ]
  end

  defp do_get_stable_versions(%State{http_client: client, stable_versions_path: stable_versions_path} = _state) do
    Logger.debug("Getting stable versions")

    with {:ok, %{body: %{"jwt" => jwt}} = _env} <- Tesla.get(client, stable_versions_path),
         {:ok, verified_resp} <- CommonCore.JWK.verify_from_home_base(jwt),
         {:ok, %{} = stable_versions} <- StableVersionsReport.new(verified_resp) do
      {:ok, stable_versions}
    else
      {:error, reason} ->
        Logger.error("Failed to get stable versions: #{inspect(reason)}")
        {:error, reason}

      unexpected ->
        Logger.error("Unexpected response from home")
        {:error, {:unexpected_response, unexpected}}
    end
  end

  defp do_get_status(%State{http_client: client, status_path: status_path} = _state) do
    Logger.debug("Getting status")

    with {:ok, %{body: %{"jwt" => jwt}} = _env} <- Tesla.get(client, status_path),
         {:ok, verified_resp} <- CommonCore.JWK.verify_from_home_base(jwt),
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
    end
  end

  defp do_export_snapshot(%State{http_client: client, project_snapshot_path: project_snapshot_path} = state, snapshot) do
    case Tesla.post(client, project_snapshot_path, %{jwt: encrypt(state, snapshot)}) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to send snapshot report: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp sign(%State{control_jwk: jwk}, data) do
    jwk |> JOSE.JWT.sign(data) |> elem(1)
  end

  defp encrypt(%State{control_jwk: jwk}, data) do
    CommonCore.JWK.encrypt_to_home_base(jwk, data)
  end
end
