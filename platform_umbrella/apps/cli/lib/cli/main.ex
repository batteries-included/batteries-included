defmodule CLI.Main do
  @dialyzer {:nowarn_function, start: 2}
  require Logger

  def start(_type, primary_args) do
    args = Burrito.Util.Args.get_arguments()

    Logger.warning("Args", args: args, primary_args: primary_args)

    CLI.new!()
    |> Optimus.parse!(args)
    |> CLI.run()

    Logger.flush()
    System.halt(0)
  end
end
