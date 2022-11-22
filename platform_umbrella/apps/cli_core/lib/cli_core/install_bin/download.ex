defmodule CLICore.InstallBin.Download do
  use Tesla

  require Logger

  plug Tesla.Middleware.FollowRedirects

  def download(from_url, to_path) do
    Logger.debug("download bin", from_url: from_url)

    with {:ok, %{status: 200} = response} <- get(from_url),
         :ok <- File.write(to_path, response.body),
         :ok <- File.chmod(to_path, 0o755) do
      {:ok, to_path}
    else
      {:error, exception} -> {:error, exception}
      err -> {:error, {:unknown_error, err}}
    end
  end
end
