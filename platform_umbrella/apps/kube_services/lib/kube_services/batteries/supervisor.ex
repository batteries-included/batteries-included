defmodule KubeServices.Batteries.Supervisor do
  @doc """
  This is a macro to create a supervisor that will run for each battery with the correct child spect to run on the dynamic supervisor and not conflict.
  """
  defmacro __using__(_opts) do
    quote do
      use Supervisor

      def child_spec(opts \\ []) do
        {:ok, %{id: id} = _battery} = Keyword.fetch(opts, :battery)

        %{
          id: id,
          start: {__MODULE__, :start_link, [opts]},
          restart: :transient
        }
      end

      def start_link(opts) do
        {:ok, battery} = Keyword.fetch(opts, :battery)

        Supervisor.start_link(__MODULE__, opts, name: via(battery))
      end

      def via(%{id: id} = battery) do
        KubeServices.Batteries.via(battery)
      end
    end
  end
end
