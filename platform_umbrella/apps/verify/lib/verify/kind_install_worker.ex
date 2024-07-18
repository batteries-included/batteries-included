defmodule Verify.KindInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  require Logger

  typedstruct module: State do
    field :bi_binary, :string
  end

  @state_opts ~w(bi_binary)a

  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.put_new_lazy(:bi_binary, &Verify.Bin.find_bi/0)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(args) do
    state = struct!(State, args)

    Logger.info("Starting KindInstallWorker with BI binary at #{state.bi_binary}")

    {:ok, state}
  end
end
