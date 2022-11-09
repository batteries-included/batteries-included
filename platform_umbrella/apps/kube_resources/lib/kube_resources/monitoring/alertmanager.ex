defmodule KubeResources.Alertmanager do
  use KubeExt.IncludeResource,
    alertmanager_yaml: "priv/raw_files/prometheus_stack/alertmanager.yaml"

  use KubeExt.ResourceGenerator

  alias KubeExt.Builder, as: B
  alias KubeExt.KubeState.Hosts
  alias KubeExt.Secret

  alias KubeResources.IstioConfig.VirtualService
  alias KubeResources.MonitoringSettings, as: Settings

  @app_name "alertmanager"
  @url_base "/x/alertmanager"

  def view_url, do: view_url(KubeExt.cluster_type())

  def view_url(:dev), do: url()

  def view_url(_), do: "/services/monitoring/alertmanager"

  def url, do: "http://#{Hosts.control_host()}#{@url_base}"

  def virtual_service(battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:istio_virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("alertmanager")
    |> B.spec(VirtualService.rewriting(@url_base, "battery-prometheus-alertmanager"))
  end

  resource(:alertmanager, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:alertmanager)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "alertmanagerConfigNamespaceSelector" => %{},
      "alertmanagerConfigSelector" => %{},
      "externalUrl" => url(),
      "image" => "quay.io/prometheus/alertmanager:v0.24.0",
      "listenLocal" => false,
      "logFormat" => "logfmt",
      "logLevel" => "info",
      "paused" => false,
      "portName" => "http-web",
      "replicas" => 1,
      "retention" => "120h",
      "routePrefix" => "/",
      "securityContext" => %{
        "fsGroup" => 2000,
        "runAsGroup" => 2000,
        "runAsNonRoot" => true,
        "runAsUser" => 1000
      },
      "serviceAccountName" => "battery-prometheus-alertmanager",
      "version" => "v0.24.0"
    })
  end

  resource(:secret_alertmanager_alertmanager, battery, _state) do
    namespace = Settings.namespace(battery.config)

    data =
      %{} |> Map.put("alertmanager.yaml", get_resource(:alertmanager_yaml)) |> Secret.encode()

    B.build_resource(:secret)
    |> B.name("alertmanager-battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.data(data)
  end

  resource(:service_account_alertmanager, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_alertmanager, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("self-monitor", "true")
    |> B.spec(%{
      "ports" => [
        %{"name" => "http-web", "port" => 9093, "protocol" => "TCP", "targetPort" => 9093}
      ],
      "selector" => %{
        "alertmanager" => "battery-prometheus-alertmanager"
      },
      "type" => "ClusterIP"
    })
  end

  resource(:service_monitor_alertmanager, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_monitor)
    |> B.name("battery-prometheus-alertmanager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [%{"path" => "/metrics", "port" => "http-web"}],
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "self-monitor" => "true"
        }
      }
    })
  end

  resource(:prometheus_rule_battery_kube_st_alertmanager_rules, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-prometheus-alertmanager.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.label("app", "kube-prometheus-stack")
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "alertmanager.rules",
          "rules" => [
            %{
              "alert" => "AlertmanagerFailedReload",
              "annotations" => %{
                "description" =>
                  "Configuration has failed to load for {{ $labels.namespace }}/{{ $labels.pod}}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagerfailedreload",
                "summary" => "Reloading an Alertmanager configuration has failed."
              },
              "expr" =>
                "# Without max_over_time, failed scrapes could create false negatives, see\n# https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.\nmax_over_time(alertmanager_config_last_reload_successful{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}[5m]) == 0",
              "for" => "10m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "AlertmanagerMembersInconsistent",
              "annotations" => %{
                "description" =>
                  "Alertmanager {{ $labels.namespace }}/{{ $labels.pod}} has only found {{ $value }} members of the {{$labels.job}} cluster.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagermembersinconsistent",
                "summary" =>
                  "A member of an Alertmanager cluster has not found all other cluster members."
              },
              "expr" =>
                "# Without max_over_time, failed scrapes could create false negatives, see\n# https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.\n  max_over_time(alertmanager_cluster_members{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}[5m])\n< on (namespace,service) group_left\n  count by (namespace,service) (max_over_time(alertmanager_cluster_members{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}[5m]))",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "AlertmanagerFailedToSendAlerts",
              "annotations" => %{
                "description" =>
                  "Alertmanager {{ $labels.namespace }}/{{ $labels.pod}} failed to send {{ $value | humanizePercentage }} of notifications to {{ $labels.integration }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagerfailedtosendalerts",
                "summary" => "An Alertmanager instance failed to send notifications."
              },
              "expr" =>
                "(\n  rate(alertmanager_notifications_failed_total{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}[5m])\n/\n  rate(alertmanager_notifications_total{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}[5m])\n)\n> 0.01",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "AlertmanagerClusterFailedToSendAlerts",
              "annotations" => %{
                "description" =>
                  "The minimum notification failure rate to {{ $labels.integration }} sent from any instance in the {{$labels.job}} cluster is {{ $value | humanizePercentage }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagerclusterfailedtosendalerts",
                "summary" =>
                  "All Alertmanager instances in a cluster failed to send notifications to a critical integration."
              },
              "expr" =>
                "min by (namespace,service, integration) (\n  rate(alertmanager_notifications_failed_total{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\", integration=~`.*`}[5m])\n/\n  rate(alertmanager_notifications_total{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\", integration=~`.*`}[5m])\n)\n> 0.01",
              "for" => "5m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "AlertmanagerClusterFailedToSendAlerts",
              "annotations" => %{
                "description" =>
                  "The minimum notification failure rate to {{ $labels.integration }} sent from any instance in the {{$labels.job}} cluster is {{ $value | humanizePercentage }}.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagerclusterfailedtosendalerts",
                "summary" =>
                  "All Alertmanager instances in a cluster failed to send notifications to a non-critical integration."
              },
              "expr" =>
                "min by (namespace,service, integration) (\n  rate(alertmanager_notifications_failed_total{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\", integration!~`.*`}[5m])\n/\n  rate(alertmanager_notifications_total{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\", integration!~`.*`}[5m])\n)\n> 0.01",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "AlertmanagerConfigInconsistent",
              "annotations" => %{
                "description" =>
                  "Alertmanager instances within the {{$labels.job}} cluster have different configurations.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagerconfiginconsistent",
                "summary" =>
                  "Alertmanager instances within the same cluster have different configurations."
              },
              "expr" =>
                "count by (namespace,service) (\n  count_values by (namespace,service) (\"config_hash\", alertmanager_config_hash{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"})\n)\n!= 1",
              "for" => "20m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "AlertmanagerClusterDown",
              "annotations" => %{
                "description" =>
                  "{{ $value | humanizePercentage }} of Alertmanager instances within the {{$labels.job}} cluster have been up for less than half of the last 5m.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagerclusterdown",
                "summary" =>
                  "Half or more of the Alertmanager instances within the same cluster are down."
              },
              "expr" =>
                "(\n  count by (namespace,service) (\n    avg_over_time(up{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}[5m]) < 0.5\n  )\n/\n  count by (namespace,service) (\n    up{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}\n  )\n)\n>= 0.5",
              "for" => "5m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "AlertmanagerClusterCrashlooping",
              "annotations" => %{
                "description" =>
                  "{{ $value | humanizePercentage }} of Alertmanager instances within the {{$labels.job}} cluster have restarted at least 5 times in the last 10m.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/alertmanager/alertmanagerclustercrashlooping",
                "summary" =>
                  "Half or more of the Alertmanager instances within the same cluster are crashlooping."
              },
              "expr" =>
                "(\n  count by (namespace,service) (\n    changes(process_start_time_seconds{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}[10m]) > 4\n  )\n/\n  count by (namespace,service) (\n    up{job=\"battery-prometheus-alertmanager\",namespace=\"battery-core\"}\n  )\n)\n>= 0.5",
              "for" => "5m",
              "labels" => %{"severity" => "critical"}
            }
          ]
        }
      ]
    })
  end
end
