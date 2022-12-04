defmodule CLICore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one, name: CLICore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
