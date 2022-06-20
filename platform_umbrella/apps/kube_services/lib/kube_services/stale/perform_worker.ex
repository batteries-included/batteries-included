defmodule KubeServices.Stale.PerformWorker do
  use Oban.Worker,
    max_attempts: 3

  alias KubeServices.Stale
  alias KubeServices.ResourceDeleter

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"stale" => suspected_stale} = _args}) do
    with {:safe_check, true} <- {:safe_check, can_delete_safe?()},
         {:delete_result, true} <- {:delete_result, perform_delete(suspected_stale)} do
      Logger.info("Successfully deleted #{length(suspected_stale)}")
      :ok
    else
      {:safe_check, false} -> {:error, :not_safe}
      {:delete_result, false} -> {:error, :delete_failed}
    end
  end

  defp can_delete_safe?, do: Stale.can_delete_safe?()

  defp perform_delete(suspected_stale) do
    suspected_stale
    |> Enum.reject(&Stale.in_some_kube_snapshot/1)
    |> Enum.map(&ResourceDeleter.delete/1)
    |> Enum.map(fn
      {:ok, _} ->
        :ok

      :ok ->
        :ok

      result ->
        Logger.debug("Delete result -> #{inspect(result)}")
        result
    end)
    |> Enum.all?(fn v -> v == :ok end)
  end
end
