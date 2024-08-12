defmodule ControlServerWeb.RedisInstanceController do
  use ControlServerWeb, :controller

  alias CommonCore.Redis.RedisInstance
  alias ControlServer.Redis

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    redis_instances = Redis.list_redis_instances()
    render(conn, :index, redis_instances: redis_instances)
  end

  def create(conn, %{"redis_instance" => redis_instance_params}) do
    with {:ok, %RedisInstance{} = redis_instance} <- Redis.create_redis_instance(redis_instance_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/redis/clusters/#{redis_instance}")
      |> render(:show, redis_instance: redis_instance)
    end
  end

  def show(conn, %{"id" => id}) do
    redis_instance = Redis.get_redis_instance!(id)
    render(conn, :show, redis_instance: redis_instance)
  end

  def update(conn, %{"id" => id, "redis_instance" => redis_instance_params}) do
    redis_instance = Redis.get_redis_instance!(id)

    with {:ok, %RedisInstance{} = redis_instance} <-
           Redis.update_redis_instance(redis_instance, redis_instance_params) do
      render(conn, :show, redis_instance: redis_instance)
    end
  end

  def delete(conn, %{"id" => id}) do
    redis_instance = Redis.get_redis_instance!(id)

    with {:ok, %RedisInstance{}} <- Redis.delete_redis_instance(redis_instance) do
      send_resp(conn, :no_content, "")
    end
  end
end
