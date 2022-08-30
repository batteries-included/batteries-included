defmodule CLI.Commands.DumpBootstrapDev do
  require Logger

  def spec do
    [
      name: "dump:bootstrap:dev",
      args: [
        outdir: [
          value_name: "OUTDIR",
          required: true
        ]
      ]
    ]
  end

  def run(_command, %{args: %{outdir: outdir}} = parse_result) do
    Logger.debug("Dumping dev bootsrap yaml = #{inspect(parse_result)}")
    KubeRawResources.Dump.dump_dev(outdir)
  end
end
