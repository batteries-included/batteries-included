defmodule CommonCore.StateSummary.KubeStorage do
  @moduledoc false
  import K8s.Resource.FieldAccessors

  alias CommonCore.StateSummary

  @doc """
  Get all of the active storage classes in the cluster.
  """
  @spec storage_classes(StateSummary.t()) :: list()
  def storage_classes(%StateSummary{kube_state: kube_state} = _summary) do
    Map.get(kube_state, :storage_class, [])
  end

  @doc """
  Finds the default storage class in the cluster. For now this relies on the
  annotation. In the future this will be a setting in some
  battery that will be configurable.
  """
  @spec default_storage_class(StateSummary.t()) :: map() | nil
  def default_storage_class(summary) do
    classes = storage_classes(summary)

    Enum.find(classes, List.first(classes), fn sc ->
      sc
      |> annotations()
      |> Map.get("storageclass.kubernetes.io/is-default-class", "false") == "true"
    end)
  end
end
