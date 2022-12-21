defmodule CLICore.KindCluster do
  require Logger

  import CLICore.InstallBin

  @spec kind_cluster ::
          {:error, [{:out, any} | {:reason, :install_failed | :start_failed}, ...]}
          | {:ok, [{:out, nonempty_binary}, ...]}
  def kind_cluster() do
    Logger.debug("Installing kind and starting local kubernetes cluster with kind...")

    with {:install, {:ok, kind_path}} <- {:install, install(:kind)},
         {:start, {:ok, out}} <- {:start, kind_start(kind_path)} do
      {:ok, out: out}
    else
      {:install, {_, out}} ->
        {:error, reason: :install_failed, out: out}

      {:start, {_, out}} ->
        {:error, reason: :start_failed, out: out}
    end
  end

  defp kind_start(kind_bin_path) do
    create_out = run_kind_command(kind_bin_path, :create)

    case run_kind_command(kind_bin_path, :get) do
      {:ok, get_out} -> {:ok, create_out: create_out, get_out: get_out}
      {status, get_err} -> {status, create_out: create_out, get_out: get_err}
    end
  end

  defp kind_command_args(action, opts \\ [])

  defp kind_command_args(:create, opts) do
    ["create", "cluster", "--name", Keyword.get(opts, :cluster_name, "battery")]
  end

  defp kind_command_args(:get, opts) do
    ["get", "kubeconfig", "--name", Keyword.get(opts, :cluster_name, "battery")]
  end

  defp run_kind_command(kind_bin_path, action) do
    args = kind_command_args(action)

    case System.cmd(kind_bin_path, args, stderr_to_stdout: true) do
      {stdouterr, 0} ->
        {:ok, stdouterr}

      {stdouterr, _} ->
        {:error, stdouterr}
    end
  end
end
