defmodule KubeExt.DockerIps do
  @default []

  def get_kind_ips do
    get_kind_ips(KubeExt.cluster_type())
  end

  defp get_kind_ips(:dev) do
    # Get all the subnets for kind.
    # However we only want ipv4 so reject anything that's ipv6
    Enum.reject(get_network_subnets("kind"), fn sub -> String.contains?(sub, ":") end)
  end

  defp get_kind_ips(_) do
    @default
  end

  def get_network_subnets(network \\ "kind") do
    case System.cmd("docker", ["network", "inspect", network]) do
      {result_string, 0} ->
        parse_subnets(result_string)

      _ ->
        @default
    end
  end

  defp parse_subnets(value) do
    value
    |> Jason.decode!()
    |> Enum.at(0)
    |> get_in(~w|IPAM Config|)
    |> Enum.map(fn config -> Map.get(config, "Subnet") end)
  end
end
