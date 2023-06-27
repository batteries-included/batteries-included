defmodule KubeServices.Stale.PerformWorker do
  use Oban.Worker,
    max_attempts: 3

  import K8s.Resource.FieldAccessors

  alias CommonCore.ApiVersionKind
  alias KubeServices.Stale
  alias KubeServices.ResourceDeleter

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"stale" => suspected_stale} = _args}) do
    Logger.debug("Starting stale perform worker")

    with {:safe_check, true} <- {:safe_check, can_delete_safe?()},
         {:verified_stale, verified_stale} <- {:verified_stale, verified_stale(suspected_stale)} do
      Logger.debug("#{length(verified_stale)} stale resources out of #{length(suspected_stale)}")
      delete(verified_stale)
    else
      {:safe_check, false} -> {:error, :not_safe}
      _ -> {:error, :unknown}
    end
  end

  defp can_delete_safe? do
    res = Stale.can_delete_safe?()
    Logger.debug("Can delete safe= #{res}")
    res
  end

  defp verified_stale(suspected_stale) do
    Logger.debug("Verifying that resources are still stale")
    seen_res_set = Stale.recent_resource_map_set()

    Enum.filter(suspected_stale, fn resource ->
      Stale.is_stale(resource, seen_res_set)
    end)
  end

  defp delete([] = _verified_stale) do
    Logger.info("There are no verified stale resources. Returning success")
    :ok
  end

  defp delete([_ | _] = verified_stale) do
    Logger.info("Going to delete #{length(verified_stale)} resources that are stale")

    all_good =
      verified_stale
      |> Enum.map(fn res ->
        kind = ApiVersionKind.resource_type!(res)
        name = name(res)
        namespace = namespace(res)

        case ResourceDeleter.delete(res) do
          {:ok, _} ->
            Logger.info("Successsfully deleted, #{kind} #{namespace} #{name}")
            :ok

          result ->
            Logger.warning(
              "Un-expected result deleting stale kind: #{kind} name: #{name} namespace: #{namespace} Result = #{inspect(result)}",
              kind: kind,
              namespace: namespace,
              name: name,
              result: result
            )

            result
        end
      end)
      |> Enum.all?(fn v -> v == :ok end)

    if all_good, do: :ok, else: {:error, :error_deleting}
  end
end
