defmodule KubeRawResources.Dump do
  alias KubeRawResources.ServiceConfigs
  alias KubeRawResources.ConfigGenerator

  require Logger

  def write_to(config, outdir, prefix \\ nil) when is_map(config) do
    doc = Ymlr.document!({"Auto-generated by KubeRawResources.Dump", config})

    meta = Map.get(config, "metadata")
    kind = Map.get(config, "kind")
    name = Map.get(meta, "name")
    namespace = Map.get(meta, "namespace", "_cluster")

    # if it's a regular k8s object, skip the prefix
    version = Map.get(config, "apiVersion")

    long_kind =
      if version == "v1" || String.contains?(version, "k8s.io") do
        kind
      else
        prefix = version |> String.split("/") |> Enum.take(1)
        "#{prefix}/#{kind}"
      end

    # outpath should look like outputs/<scope>/<kind>/<name>.yaml
    outdir =
      if prefix do
        Path.join([outdir, prefix])
      else
        Path.join([outdir, namespace, long_kind])
      end

    File.mkdir_p!(outdir)

    outpath = "#{outdir}/#{name}.yaml"
    Logger.info("Writing #{outpath}")

    outpath
    |> File.open!([:write, :utf8])
    |> IO.puts(doc)
  end

  defp dump_services(services, outdir) do
    services
    |> Enum.flat_map(fn service_type ->
      service_type
      |> ConfigGenerator.materialize()
      |> Enum.map(fn {key, value} ->
        {Path.join("/#{Atom.to_string(service_type)}", key), value}
      end)
    end)
    |> Enum.reduce(%{}, fn r_map, acc -> Map.merge(acc, r_map) end)
    |> Enum.each(fn
      {fname, configs} when is_list(configs) ->
        Enum.map(configs, &write_to(&1, outdir, fname))

      {fname, config} ->
        write_to(config, outdir, fname)
    end)
  end

  def dump_dev(outdir) do
    dump_services(ServiceConfigs.dev_services(), outdir)
  end

  def dump_prod(outdir) do
    dump_services(ServiceConfigs.prod_services(), outdir)
  end
end
