defmodule ServerWeb.RawConfigController do
  use ServerWeb, :controller

  import Ecto.Query

  alias Server.Configs
  alias Server.Configs.RawConfig
  alias Server.Repo

  action_fallback ServerWeb.FallbackController

  def index(conn, params = %{"kube_cluster_id" => kube_cluster_id}) do
    {:ok, filter} =
      Server.FilterConfig.raw_configs()
      |> Filtrex.parse_params(Map.delete(params, "kube_cluster_id"))

    raw_configs =
      from(rc in RawConfig,
        where: rc.kube_cluster_id == ^kube_cluster_id,
        select: rc
      )
      |> Filtrex.query(filter)
      |> Repo.all()

    render(conn, "index.json", raw_configs: raw_configs)
  end

  def create(conn, %{"raw_config" => raw_config_params, "kube_cluster_id" => kube_cluster_id}) do
    create_params = Map.put(raw_config_params, "kube_cluster_id", kube_cluster_id)

    with {:ok, %RawConfig{} = raw_config} <- Configs.create_raw_config(create_params) do
      conn
      |> put_status(:created)
      |> put_resp_header(
        "location",
        Routes.kube_cluster_raw_config_path(conn, :show, kube_cluster_id, raw_config)
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
