defmodule KubeBootstrap.Kube do
  require Logger

  @max_retries 20

  @spec ensure_exists(K8s.Conn.t(), list(map())) ::
          {:error, any()} | {:ok, list()}
  def ensure_exists(%K8s.Conn{} = conn, resources) do
    num_retries = @max_retries
    ensure_exists(conn, resources, num_retries)
  end

  defp ensure_exists(_conn, _resources, 0), do: {:error, :retries_exhausted}

  defp ensure_exists(conn, resources, num_retries) do
    # In parallel try to create all the resources
    # This also enforces a timeout
    results =
      resources
      |> Task.async_stream(fn resource -> find_or_create(conn, resource) end,
        timeout: 180_000,
        ordered: true,
        max_concurrency: 5
      )
      |> Enum.to_list()
      # async_stream returns {:ok, result} or {:error, reason}
      # We don't care that the task was successful, just the result
      # unless it couldn't be run at all
      |> Enum.map(fn
        {:ok, result} ->
          result

        {:error, reason} ->
          Logger.warning("Failed to create resource #{inspect(reason)}", reason: reason)
          {:error, reason}
      end)

    if Enum.all?(results, &result_ok?/1) do
      Logger.info("All #{length(resources)} resource(s) created successfully")
      {:ok, results}
    else
      retries_left = num_retries - 1
      sleep_time = sleep_time(retries_left)

      if sleep_time > 0 do
        Logger.info("Retrying in #{sleep_time}ms...", retries_left: retries_left)

        :timer.sleep(sleep_time)
      end

      ensure_exists(conn, resources, retries_left)
    end
  end

  @spec result_ok?(any()) :: boolean()
  defp result_ok?(:ok), do: true
  defp result_ok?({:ok, _}), do: true
  defp result_ok?(_), do: false

  @spec sleep_time(non_neg_integer()) :: non_neg_integer()
  # For the last one we have already
  defp sleep_time(0), do: 0

  defp sleep_time(retries_remaining) do
    # Exponential backoff

    (:math.pow(2, @max_retries - retries_remaining) * 500) |> min(10_000) |> trunc()
  end

  defp find_or_create(conn, resource) do
    case resource
         |> K8s.Client.get()
         |> K8s.Client.put_conn(conn)
         |> K8s.Client.run() do
      {_, :not_found} ->
        create(conn, resource)

      {:error, %K8s.Client.APIError{reason: "NotFound"}} ->
        create(conn, resource)

      {:error, %K8s.Operation.Error{message: "NotFound"}} ->
        create(conn, resource)

      {:error, %K8s.Discovery.Error{message: _}} ->
        create(conn, resource)

      {:error, :not_found} ->
        create(conn, resource)

      {:ok, _} = result ->
        result

      {:error, _} = error ->
        error
    end
  end

  defp create(conn, resource) do
    resource
    |> K8s.Client.create()
    |> K8s.Client.put_conn(conn)
    |> K8s.Client.run()
  end
end
