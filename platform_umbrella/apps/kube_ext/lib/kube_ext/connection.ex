defmodule KubeExt.Connection do
  def get, do: get(Application.get_env(:kube_ext, :cluster_type, :dev))

  defp get(:dev) do
    K8s.Conn.from_file("~/.kube/config")
  end

  defp get(:service_account) do
    K8s.Conn.from_service_account()
  end
end
