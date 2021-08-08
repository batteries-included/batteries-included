defmodule KubeServices.BaseServicesSupervisor do
  use DynamicSupervisor

  alias ControlServer.Services.BaseService
  alias KubeServices.Worker

  def start_link(_init_args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_child(%BaseService{} = base_service) do
    child_spec = %{id: Worker, start: {Worker, :start_link, [base_service]}}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
