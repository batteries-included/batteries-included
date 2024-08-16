defmodule ControlServerWeb.Plug.InstallStatus do
  @moduledoc false
  import Phoenix.Controller
  import Plug.Conn

  alias CommonCore.ET.InstallStatus
  alias KubeServices.ET.InstallStatusWorker

  def init(opts \\ []) do
    opts
  end

  def call(conn, _opts) do
    if battery_services_running?() do
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
      |> redirect(to: InstallStatus.redirect_path(status))
      |> halt()
    end
  end

  def battery_services_running?, do: KubeServices.Application.start_services?()
end
