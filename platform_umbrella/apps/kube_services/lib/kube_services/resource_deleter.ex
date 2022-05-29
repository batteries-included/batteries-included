defmodule KubeServices.ResourceDeleter do
  use GenServer

  alias K8s.Resource.FieldAccessors

  require Logger

  @me __MODULE__

  def start_link(opts) do
    {:ok, pid} = result = GenServer.start_link(@me, opts, name: @me)
    Logger.debug("#{@me} GenServer started with# #{inspect(pid)}.")
    result
  end

  @impl true
  def init(opts) do
    conn_func = Keyword.get(opts, :connection_func, fn -> KubeExt.ConnectionPool.get() end)
    conn = Keyword.get_lazy(opts, :connection, conn_func)
    {:ok, %{conn: conn}}
  end

  def delete(resource) do
    GenServer.call(@me, {:delete, resource})
  end

  @impl true
  def handle_call({:delete, resource}, _fromt, %{conn: conn} = state) do
    Logger.debug("Delete of resource #{inspect(summarize(resource))}")
    operation = K8s.Client.delete(resource)

    {:reply, K8s.Client.run(conn, operation), state}
  end

  defp summarize(resource) do
    %{
      api_version: FieldAccessors.api_version(resource),
      kind: FieldAccessors.kind(resource),
      name: FieldAccessors.name(resource)
    }
  end
end
