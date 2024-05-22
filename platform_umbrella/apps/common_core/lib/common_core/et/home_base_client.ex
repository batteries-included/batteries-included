defmodule CommonCore.ET.HomeBaseClient do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ET.UsageReport

  require Logger

  typedstruct module: State do
    field :home_url, String.t()
    field :http_client, Tesla.Client.t(), default: nil
  end

  @me __MODULE__
  @state_opts ~w(home_url)a

  def send_usage(client \\ @me, state_summary) do
    GenServer.call(client, {:send_usage, state_summary})
  end

  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  def init(opts) do
    # Get the default url we'll need that to create the http client
    home_url = Keyword.fetch!(opts, :home_url)

    state = struct!(State, home_url: home_url, http_client: nil)
    build_client(state)
  end

  def handle_call({:send_usage, state_summary}, _, state) do
    Logger.info("Sending usage to #{state.home_url}")
    {:reply, do_send_usage(state, state_summary), state}
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

  defp do_send_usage(%{http_client: client} = _state, state_summary) do
    with {:ok, usage_report} <- UsageReport.new(state_summary),
         # since the path is dependent on the install id, get that here
         report_path = CommonCore.ET.URLs.usage_report_path(state_summary),
         # Push the report to the reports path for the install
         {:ok, _} <- Tesla.post(client, report_path, %{usage_report: usage_report}) do
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
end
