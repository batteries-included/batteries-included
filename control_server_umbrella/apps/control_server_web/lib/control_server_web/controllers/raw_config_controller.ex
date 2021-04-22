defmodule ControlServerWeb.RawConfigController do
  use ControlServerWeb, :controller

  alias ControlServer.Configs
  alias ControlServer.Configs.RawConfig

  action_fallback ControlServerWeb.FallbackController

  def index(conn, %{} = _params) do
    raw_configs = Configs.list_raw_configs()
    render(conn, "index.json", raw_configs: raw_configs)
  end

  def create(conn, %{"raw_config" => raw_config_params}) do
    with {:ok, %RawConfig{} = raw_config} <- Configs.create_raw_config(raw_config_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.raw_config_path(conn, :show, raw_config)
      )
      |> render("show.json", raw_config: raw_config)
    end
  end

  def show(conn, %{"id" => id}) do
    raw_config = Configs.get_raw_config!(id)
    render(conn, "show.json", raw_config: raw_config)
  end

  def update(conn, %{"id" => id, "raw_config" => raw_config_params}) do
    raw_config = Configs.get_raw_config!(id)

    with {:ok, %RawConfig{} = raw_config} <-
           Configs.update_raw_config(raw_config, raw_config_params) do
      render(conn, "show.json", raw_config: raw_config)
    end
  end

  def delete(conn, %{"id" => id}) do
    raw_config = Configs.get_raw_config!(id)

    with {:ok, %RawConfig{}} <- Configs.delete_raw_config(raw_config) do
      send_resp(conn, :no_content, "")
    end
  end
end
