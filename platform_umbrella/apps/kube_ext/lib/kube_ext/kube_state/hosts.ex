defmodule KubeExt.KubeState.Hosts do
  alias KubeExt.KubeState.IstioIngress

  def control_host do
    host("control")
  end

  def gitea_host do
    host("gitea")
  end

  def harbor_host do
    host("harbor")
  end

  def knative, do: host("knative")

  defp host(name) do
    ip = IstioIngress.single_address()
    "#{name}.#{ip}.ip.batteriesincl.com"
  end
end
