defmodule CLI.Commands.DumpBootstrapProd do
  require Logger

  def spec do
    [
      name: "dump:bootstrap:prod",
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
    KubeResources.Dump.dump_prod(outdir)
  end
end
