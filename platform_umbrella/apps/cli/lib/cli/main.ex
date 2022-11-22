defmodule CLI.Main do
  @dialyzer {:nowarn_function, _main: 0}
  use Bakeware.Script

  require Logger

  @impl Bakeware.Script
  def main(args \\ []) do
    CLI.new!()
    |> Optimus.parse!(args)
    |> CLI.run()

    Logger.flush()
    0
  end
end
