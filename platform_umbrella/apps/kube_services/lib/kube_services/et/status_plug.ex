defmodule KubeServices.ET.StatusPlug do
  @moduledoc false
  import Plug.Conn

  alias CommonCore.ET.InstallStatus
  alias KubeServices.ET.InstallStatusWorker

  def init(opts \\ []) do
    opts
  end

  def call(conn, _opts) do
    if KubeServices.Application.start_services?() do
      status = InstallStatusWorker.get_status()
      maybe_redirect(conn, status)
    else
      # If we are in test mode and there are no
      # kube services running, we should
      # assume everything is fine
      conn
    end
  end

  defp maybe_redirect(conn, status) do
    if InstallStatus.status_ok?(status) do
      conn
    else
      conn
      |> resp(:found, "")
      |> put_resp_header("location", InstallStatus.redirect_path(status))
      |> send_resp()
      |> halt()
    end
  end
end
