defmodule KubeResources.CrdWebhook do
  def change_conversion(%{"spec" => %{"conversion" => %{}}} = crd, service_name, namespace),
    do: do_change_conversion(crd, service_name, namespace)

  def change_conversion(%{spec: %{conversion: %{}}} = crd, service_name, namespace),
    do: do_change_conversion(crd, service_name, namespace)

  def change_conversion(crd, _, _), do: crd

  defp do_change_conversion(crd, service_name, namespace) do
    update_in(crd, ~w(spec conversion webhook clientConfig service), fn s ->
      (s || %{})
      |> Map.put("name", service_name)
      |> Map.put("namespace", namespace)
    end)
  end
end
