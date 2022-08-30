defmodule CLI.Commands.DumpBootstrap do
  require Logger

  def spec do
    [
      name: "dump:bootstrap",
      args: [
        outdir: [
          value_name: "OUTDIR",
          required: true
        ]
      ]
    ]
  end

  def run(_command, %{args: %{outdir: outdir}} = _parse_result) do
    Logger.debug("Dumping production bootsrap yaml = #{outdir}")
    KubeRawResources.Dump.dump_prod(outdir)
  end
end
