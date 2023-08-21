defmodule KubeServices.Connection do
  @moduledoc false
  def get, do: get(KubeServices.cluster_type())

  defp get(:dev) do
    K8s.Conn.from_file("~/.kube/config", insecure_skip_tls_verify: true)
  end

  defp get(:service_account) do
    K8s.Conn.from_service_account()
  end
end
