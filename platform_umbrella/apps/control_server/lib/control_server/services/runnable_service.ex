defmodule ControlServer.Services.RunnableService do
  alias ControlServer.Services

  @callback default_config() :: map()
  @callback activate!() :: ControlServer.Services.BaseService
  @callback active?() :: boolean()
  @callback service_type() :: atom()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      path = Keyword.get(opts, :path)
      service_type = Keyword.get(opts, :service_type)

      @behaviour ControlServer.Services.RunnableService

      @impl ControlServer.Services.RunnableService
      def default_config do
        %{}
      end

      @impl ControlServer.Services.RunnableService
      def activate! do
        ControlServer.Services.RunnableService.activate!(
          unquote(path),
          unquote(service_type),
          default_config()
        )
      end

      @impl ControlServer.Services.RunnableService
      def active? do
        p = unquote(path)
        ControlServer.Services.RunnableService.active?(p)
      end

      @impl ControlServer.Services.RunnableService
      def service_type do
        unquote(service_type)
      end

      defoverridable ControlServer.Services.RunnableService
    end
  end

  def activate!(path, service_type, config) do
    Services.find_or_create!(%{
      is_active: true,
      root_path: path,
      service_type: service_type,
      config: config
    })
  end

  def active?(path), do: Services.active?(path)
end
