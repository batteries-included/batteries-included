defmodule KubeResources.Grafana do
  @moduledoc """
  Add on context for Grafana configuration.
  """

  alias KubeExt.Builder, as: B

  alias KubeExt.IniConfig
  alias KubeResources.GrafanaDashboards
  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.MonitoringSettings

  @datasources_configmap "grafana-datasources"
  @main_configmap "grafana-config"

  @prometheus_datasource_name "battery-prometheus"

  @port 3000
  @port_name "http"

  @app_name "grafana"

  def materialize(config) do
    {depl, dashboards} = config |> deployment() |> GrafanaDashboards.add_dashboards(config)

    %{
      "/grafana/service_account" => service_account(config),
      "/grafana/prometheus_datasource" => prometheus_datasource_config(config),
      "/grafana/main_config" => main_config(config),
      "/grafana/grafana_deployment" => depl,
      "/grafana/dashboards" => dashboards,
      "/grafana/grafana_service" => service(config)
    }
  end

  def ingress(config) do
    namespace = MonitoringSettings.namespace(config)

    B.build_resource(:ingress, "/x/grafana", "grafana", "http")
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def virtual_service(config) do
    namespace = MonitoringSettings.namespace(config)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("grafana")
    |> B.spec(VirtualService.prefix("/x/grafana", "grafana"))
  end

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("battery-grafana")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  def prometheus_datasource_config(config) do
    namespace = MonitoringSettings.namespace(config)

    file_contents =
      Ymlr.Encoder.to_s!(%{
        "apiVersion" => 1,
        "datasources" => [
          %{
            "access" => "proxy",
            "editable" => false,
            "name" => @prometheus_datasource_name,
            "orgId" => 1,
            "type" => "prometheus",
            "url" => "http://prometheus-operated.#{namespace}.svc:9090",
            "version" => 1
          }
        ]
      })

    B.build_resource(:config_map)
    |> B.app_labels(@app_name)
    |> B.name(@datasources_configmap)
    |> B.namespace(namespace)
    |> Map.put("data", %{"prometheus.yaml" => file_contents})
  end

  def main_config(config) do
    namespace = MonitoringSettings.namespace(config)

    config = %{
      "server" => %{
        root_url: "/x/grafana",
        serve_from_sub_path: true
      },
      "auth.anonymous" => %{
        enabled: true
      },
      "security" => %{
        allow_embedding: true
      },
      "users" => %{default_theme: "light"},
      "analytics" => %{reporting_enabled: false},
      "log" => %{
        "mode" => "console",
        "info" => "debug"
      }
    }

    file_contents = IniConfig.to_ini(config)

    B.build_resource(:config_map)
    |> B.app_labels(@app_name)
    |> B.name(@main_configmap)
    |> B.namespace(namespace)
    |> Map.put("data", %{"grafana.ini" => file_contents})
  end

  def deployment(config) do
    namespace = MonitoringSettings.namespace(config)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("template", deployment_template(config))
      |> B.match_labels_selector(@app_name)

    B.build_resource(:deployment)
    |> B.app_labels(@app_name)
    |> B.name("grafana")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def service(config) do
    namespace = MonitoringSettings.namespace(config)

    spec =
      %{}
      |> Map.put("ports", [%{"name" => @port_name, "port" => @port, "targetPort" => @port_name}])
      |> B.short_selector(@app_name)

    B.build_resource(:service)
    |> B.namespace(namespace)
    |> B.name("grafana")
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  def monitors(config) do
    namespace = MonitoringSettings.namespace(config)

    spec =
      %{}
      |> Map.put("endpoints", [%{"interval" => "15s", "port" => @port_name}])
      |> B.match_labels_selector(@app_name)

    [
      B.build_resource(:service_monitor)
      |> B.app_labels(@app_name)
      |> B.name("grafana")
      |> B.namespace(namespace)
      |> B.spec(spec)
    ]
  end

  defp container(config) do
    image = MonitoringSettings.grafana_image(config)
    version = MonitoringSettings.grafana_version(config)

    %{}
    |> Map.put("image", "#{image}:#{version}")
    |> Map.put("name", "grafana")
    |> Map.put("env", [])
    |> Map.put("resources", %{
      "limits" => %{
        "cpu" => "200m",
        "memory" => "200Mi"
      },
      "requests" => %{
        "cpu" => "100m",
        "memory" => "100Mi"
      }
    })
    |> Map.put("ports", [%{"containerPort" => @port, "name" => @port_name}])
    |> Map.put("readinessProbe", %{
      "httpGet" => %{
        "path" => "/api/health",
        "port" => @port_name
      }
    })
    |> Map.put("volumeMounts", [
      %{
        "mountPath" => "/var/lib/grafana",
        "name" => "grafana-storage",
        "readOnly" => false
      },
      %{
        "mountPath" => "/etc/grafana/grafana.ini",
        "subPath" => "grafana.ini",
        "name" => @main_configmap,
        "readOnly" => true
      },
      %{
        "mountPath" => "/etc/grafana/provisioning/datasources",
        "name" => @datasources_configmap,
        "readOnly" => false
      }
    ])
  end

  defp volumes(_config) do
    [
      %{
        "emptyDir" => %{},
        "name" => "grafana-storage"
      },
      %{
        "name" => @datasources_configmap,
        "configMap" => %{
          "name" => @datasources_configmap
        }
      },
      %{
        "name" => @main_configmap,
        "configMap" => %{
          "name" => @main_configmap
        }
      }
    ]
  end

  defp deployment_template(config) do
    %{}
    |> B.app_labels(@app_name)
    |> Map.put(
      "spec",
      %{
        "containers" => [container(config)],
        "nodeSelector" => %{
          "beta.kubernetes.io/os": "linux"
        },
        "securityContext" => %{
          "runAsNonRoot" => true,
          "runAsUser" => 65_534
        },
        "serviceAccountName" => "battery-grafana",
        "volumes" => volumes(config)
      }
    )
  end
end
