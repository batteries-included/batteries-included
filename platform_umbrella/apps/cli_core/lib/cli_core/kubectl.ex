defmodule CLICore.Kubectl do
  require Logger

  import CLICore.InstallBin

  alias KubeExt.SpiloMaster

  def postgres_forward_control() do
    postgres_forward("pg-control", "battery-base", 5432)
  end

  @spec postgres_forward(String.t(), String.t(), non_neg_integer()) ::
          {:error,
           [{:out, any} | {:reason, :install_failed | :pod_enoent | :port_forward_failed}, ...]}
  def postgres_forward(cluster, namespace, port) do
    # Large multi-step process. We have to make sure that each step is correct
    # before going on. If we fail, return an error tuple with the reason.
    #
    # Ensure that kubectl is installed somewhere, getting the path
    # Then get the pod name by going to Kubernetes
    # Then run the forward command.
    with {:install, {:ok, path}} <- {:install, install(:kubectl)},
         {:get_pod, {:ok, pod}} <- {:get_pod, master_pod_name(cluster, namespace)},
         {:args, args} <-
           {:args, args(:port_forward, target: pod, port: port, namespace: namespace)},
         {:port_forward, {:ok, out}} <- {:port_forward, run(path, args)} do
      {:ok, out: out}
    else
      {:install, {_, out}} -> {:error, reason: :install_failed, out: out}
      {:get_pod, {_, out}} -> {:error, reason: :pod_enoent, out: out}
      {:port_forward, {_, out}} -> {:error, reason: :port_forward_failed, out: out}
    end
  end

  # Go out to KubeExt and Kubernetes
  # cluster and get the name of the master pod
  defp master_pod_name(cluster, namespace) do
    case SpiloMaster.get_master_pod(cluster, namespace) do
      # If it was a success and it has a name then return the ok tuple
      {:ok, %{"metadata" => %{"name" => name}} = _pod} ->
        Logger.debug("Found master pod cluster #{cluster}. Found pod/#{name}")
        {:ok, name}

      # Otherwise handle the errors
      {:error, _} = err ->
        err

      _ ->
        {:error, "unknown"}
    end
  end

  defp args(:port_forward, opts) do
    target_pod_name = Keyword.fetch!(opts, :target)
    port = Keyword.fetch!(opts, :port)
    namespace = Keyword.fetch!(opts, :namespace)

    [
      "port-forward",
      "pods/#{target_pod_name}",
      "#{port}:#{port}",
      "-n",
      namespace,
      "--address",
      "0.0.0.0"
    ]
  end

  defp run(path, args) do
    Logger.debug("Running kubectl path = #{path} args = #{inspect(args)}")

    # we wrap the command in a script to ensure that the process dies
    # with the erlang vm when it gets torn down
    shell_snippet = ~s"""
    #{path} #{Enum.join(args, " ")} &
    pid=$!

    exec >/dev/null 2>&1

    trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

    wait $pid
    exit $?
    """

    case System.cmd("/usr/bin/env", ["bash", "-c", shell_snippet], stderr_to_stdout: true) do
      {stdouterr, 0} ->
        {:ok, stdouterr}

      {stdouterr, 1} ->
        {:error, stdouterr}
    end
  end
end
