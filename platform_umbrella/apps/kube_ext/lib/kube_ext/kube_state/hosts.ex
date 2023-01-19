defmodule KubeExt.KubeState.Hosts do
  alias KubeExt.KubeState.IstioIngress

  def control_host do
    host("control")
  end

  def gitea_host do
    host("gitea")
  end

  def grafana_host do
    host("grafana")
  end

  def vmselect_host do
    host("vmselect")
  end

  def vmagent_host do
    host("vmagent")
  end

  def harbor_host do
    host("harbor")
  end

  def mailhog_host do
    host("mailhog")
  end

  def knative, do: host("webapp", "user")

  defp host(name, group \\ "core") do
    ip = IstioIngress.single_address()
    "#{name}.#{group}.#{ip}.ip.batteriesincl.com"
  end
end
