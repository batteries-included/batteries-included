defmodule CLI.Command do
  require Logger

  @version "0.4.0"

  defp registered_commands do
    Application.get_env(:cli, CLI.Commands)
  end

  @spec new! :: Optimus.t()
  def new! do
    Optimus.new!(
      name: "bicli",
      description: "Batteries Included CLI",
      version: @version,
      subcommands: subcommands()
    )
  end

  defp subcommands do
    Enum.map(
      registered_commands(),
      fn {key, cmd} -> {key, cmd.spec()} end
    )
  end

  defp command(command_key), do: Keyword.get(registered_commands(), command_key)

  def run({[command_key], %Optimus.ParseResult{} = parse_result}) do
    command_key
    |> command()
    |> then(fn module -> module.run(command_key, parse_result) end)
  end

  def run(argv) do
    Logger.debug("Fallback run used")

    new!()
    |> Optimus.parse!(argv)
    |> IO.puts()
  end
end
