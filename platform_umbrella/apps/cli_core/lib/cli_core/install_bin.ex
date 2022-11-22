defmodule CLICore.InstallBin do
  import CLICore.InstallBin.Download
  import CLICore.InstallBin.BinFacts

  require Logger

  @spec install(atom) :: {:error, any} | {:ok, binary}
  def install(type)

  def install(type) when is_atom(type) do
    case install_path(type) do
      {:ok, path} ->
        {:ok, path}

      :missing ->
        do_install(type)
    end
  end

  defp do_install(type) do
    with :ok <- make_install_bin(),
         url = url(type),
         location <- install_location(type),
         {:ok, final_path} <- download(url, location) do
      {:ok, final_path}
    else
      err -> err
    end
  end

  defp install_path(type) do
    location = install_location(type)

    cond do
      {:ok, path} = which(type) ->
        {:ok, path}

      File.exists?(location) ->
        {:ok, location}

      true ->
        :missing
    end
  end

  defp which(type) do
    case System.cmd("which", [to_string(type)]) do
      {path, 0} ->
        {:ok, String.trim(path)}

      {_, 1} ->
        :missing

      _ ->
        :error
    end
  end

  defp make_install_bin do
    bin_dir = install_bin()
    Logger.debug("Creating bin dir", bin_dir: bin_dir)
    File.mkdir_p!(bin_dir)
  end

  defp install_bin, do: Path.join(System.user_home!(), ".batteries/bin")

  defp install_location(type),
    do: Path.join(install_bin(), to_string(type))
end
