defmodule KubeExt.Connection do
  def get, do: get(KubeExt.cluster_type())

  defp get(:dev) do
    K8s.Conn.from_file("~/.kube/config", insecure_skip_tls_verify: true)
  end

  defp get(:service_account) do
    K8s.Conn.from_service_account()
  end
end
