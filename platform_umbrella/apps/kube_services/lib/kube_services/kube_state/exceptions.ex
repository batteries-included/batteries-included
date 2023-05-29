defmodule KubeServices.KubeState.NoResultsError do
  defexception [:message, plug_status: 404]

  def exception(opts) do
    namespace = Keyword.fetch!(opts, :namespace)
    name = Keyword.fetch!(opts, :name)
    resource_type = Keyword.fetch!(opts, :resource_type)

    msg = """
    expected at least one result but got none for:

    Resource Type: #{inspect(resource_type)}
    Namespace: #{inspect(namespace)}
    Name: #{inspect(name)}
    """

    %__MODULE__{message: msg}
  end
end
