defmodule KubeServices.Worker do
  @moduledoc """
  Module to interact with BaseService and Kubernetes resources.
  """
  use GenServer

  alias ControlServer.ConfigGenerator
  alias ControlServer.Services

  require Logger

  def start_link(_default) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(:apply, state) do
    apply_all()
    {:noreply, state}
  end

  @impl true
  def handle_call(:apply_now, _from, state) do
    {:reply, apply_all(), state}
  end

  def apply_all(include_battery \\ false) do
    Logger.info("Applying")

    resources =
      Services.list_base_services()
      |> Enum.flat_map(fn service -> ConfigGenerator.materialize(service) end)
      |> Enum.concat(
        ConfigGenerator.materialize(%Services.BaseService{
          config: %{},
          is_active: include_battery,
          root_path: "/battery",
          service_type: :battery
        })
      )
      |> Enum.sort(fn {a, _av}, {b, _bv} -> a <= b end)
      |> Enum.map(fn {path, r} ->
        Logger.debug("Applying new config to #{path}")

        with {:ok, _} <- KubeExt.apply(r) do
          r
        end
      end)

    Logger.debug("Completed apply_all with #{length(resources)} resources")
  end
end
