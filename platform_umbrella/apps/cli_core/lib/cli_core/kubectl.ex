defmodule CLICore.Kubectl do
  require Logger

  import CLICore.InstallBin

  @spec postgres_forward_control ::
          {:error,
           [
             {:out, any}
             | {:reason, :install_failed | :namespace_enoent | :pod_enoent | :port_forward_failed},
             ...
           ]}
          | {:ok, [{:out, nonempty_binary}, ...]}
  def postgres_forward_control() do
    postgres_forward("pg-control", "battery-base", 5432)
  end

  defp postgres_forward(cluster, namespace, port) do
    with {:install, {:ok, kubectl_path}} <- {:install, install(:kubectl)},
         {:get_pod, {:ok, pod}} <-
           {:get_pod, get_spilo_master_pod(cluster, namespace)},
         {:port_forward, {:ok, out}} <-
           {:port_forward,
            run_kubectl_command(kubectl_path, :port_forward,
              target: "pods/#{pod}",
              port_map: "#{port}:5432",
              namespace: namespace
            )} do
      {:ok, out: out}
    else
      {:install, {_, out}} -> {:error, reason: :install_failed, out: out}
      {:get_pod, {_, out}} -> {:error, reason: :pod_enoent, out: out}
      {:port_forward, {_, out}} -> {:error, reason: :port_forward_failed, out: out}
    end
  end

  defp get_spilo_master_pod(cluster, namespace) do
    list_pod = K8s.Client.list("v1", "Pod", namespace: namespace)
    conn = KubeExt.ConnectionPool.get()

    {status, out} = K8s.Client.run(conn, list_pod)

    case status do
      :ok ->
        {:ok,
         out
         |> Map.get("items")
         |> Enum.filter(fn item ->
           get_in(item, ~w|metadata labels application|) == "spilo" &&
             get_in(item, ~w|metadata labels spilo-role|) == "master" &&
             get_in(item, ~w|metadata labels cluster-name|) == cluster
         end)
         |> Enum.at(0)
         |> get_in(~w|metadata name|)}

      _ ->
        {:error, "Couldn't fetch pod"}
    end
  end

  defp kubectl_command_args(:port_forward, opts) do
    [
      "port-forward",
      Keyword.fetch!(opts, :target),
      Keyword.fetch!(opts, :port_map),
      "-n",
      Keyword.fetch!(opts, :namespace),
      "--address",
      "0.0.0.0"
    ]
  end

  defp run_kubectl_command(kubectl_path, action, opts) do
    args = kubectl_command_args(action, opts)

    Logger.debug(Enum.join(args, " "))

    case System.cmd(kubectl_path, args, stderr_to_stdout: true) do
      {stdouterr, 0} ->
        {:ok, stdouterr}

      {stdouterr, 1} ->
        {:error, stdouterr}
    end
  end
end
