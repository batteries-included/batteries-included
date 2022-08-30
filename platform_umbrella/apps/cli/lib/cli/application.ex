defmodule CLI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  def should_halt, do: Application.get_env(:cli, :should_halt, false)

  @impl true
  def start(_type, _args) do
    Logger.debug("Starting")
    children = []

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CLI.Supervisor]
    res = Supervisor.start_link(children, opts)

    if should_halt() do
      # Drop the first four args. They are left over from erlang and release setup
      argv = Enum.drop(Burrito.Util.Args.get_arguments(), 4)
      Logger.debug("Args = #{inspect(argv)}")

      CLI.Command.new!()
      |> Optimus.parse!(argv)
      |> CLI.Command.run()

      Logger.flush()
      System.halt(0)
    else
      res
    end
  end
end
