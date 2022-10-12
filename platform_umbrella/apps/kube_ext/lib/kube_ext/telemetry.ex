defmodule KubeExt.Telemetry do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      Module.register_attribute(__MODULE__, :events, accumulate: true, persist: false)

      import KubeExt.Telemetry
      @name opts[:name]
      @metadata opts[:metadata] || %{}
      @before_compile KubeExt.Telemetry

      @doc false
      def metadata, do: @metadata

      @doc false
      def metadata(alt), do: Map.merge(metadata(), alt)
    end
  end

  defmacro __before_compile__(env) do
    events = Module.get_attribute(env.module, :events)

    quote bind_quoted: [events: events] do
      @doc false
      def events, do: unquote(events)
    end
  end

  defmacro defevent(arg_or_args) do
    names = event_names(arg_or_args)
    function_name = Enum.join(names, "_")

    quote do
      @event [@name | unquote(names)]
      @events @event

      # credo:disable-for-next-line
      def unquote(:"#{function_name}")(measurements, metadata \\ %{}) do
        :telemetry.execute(@event, measurements, metadata(metadata))
        :ok
      end
    end
  end

  @doc """
  Measure function execution in _ms_ and return in map w/ results.

  ## Examples
      iex> KubeExt.Sys.Event.measure(IO, :puts, ["hello"])
      {%{duration: 33}, :ok}
  """
  @spec measure(module, atom, list()) :: {map(), any()}
  def measure(mod, func, args) do
    {duration, result} = :timer.tc(mod, func, args)
    measurements = %{duration: duration}

    {measurements, result}
  end

  def measure(func, args) do
    {duration, result} = :timer.tc(func, args)
    measurements = %{duration: duration}

    {measurements, result}
  end

  defp event_names(arg) when is_list(arg), do: arg
  defp event_names(arg), do: [arg]
end
