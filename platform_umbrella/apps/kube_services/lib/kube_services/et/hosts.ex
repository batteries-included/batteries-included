defmodule KubeServices.ET.Hosts do
  @moduledoc """
  ET phones home to report hosts.
  """
  use GenServer
  use TypedStruct

  alias CommonCore.ET.HomeBaseClient
  alias CommonCore.ET.HostReport
  alias CommonCore.StateSummary

  require Logger

  typedstruct module: State do
    field :home_client, pid() | atom(), default: HomeBaseClient
    field :prev_report, HostReport.t()
  end

  @state_opts ~w(home_client_pid)a

  @impl GenServer
  @spec init() :: {:ok, struct()}
  def init(args \\ []) do
    :ok = EventCenter.SystemStateSummary.subscribe()

    {:ok, %State{home_client: Keyword.get(args, :home_client_pid, HomeBaseClient)}}
  end

  @spec start_link(Keyword.t()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    {init_args, genserver_opts} = opts |> Keyword.put_new(:name, __MODULE__) |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, init_args, genserver_opts)
  end

  @impl GenServer
  def handle_info(%StateSummary{} = summary, %State{home_client: home_client, prev_report: prev_report} = state) do
    {:ok, new_report} = HostReport.new(summary)

    new_state =
      case handle_host_report(home_client, summary, prev_report, new_report) do
        {:ok, report} ->
          struct(state, prev_report: report)

        err ->
          Logger.error("Unexpected error trying to send host report: #{inspect(err)}")
          state
      end

    {:noreply, new_state}
  end

  defp handle_host_report(_client, _summary, prev, new) when prev == new, do: {:ok, prev}

  defp handle_host_report(client, summary, _prev, new) do
    case HomeBaseClient.send_hosts(client, summary) do
      :ok -> {:ok, new}
      unexpected -> {:error, unexpected}
    end
  end
end
