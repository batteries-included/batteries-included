defmodule KubeResources.MonitoringApiServer do
  use KubeExt.IncludeResource,
    apiserver_json: "priv/raw_files/prometheus_stack/apiserver.json"

  use KubeExt.ResourceGenerator

  alias KubeResources.MonitoringSettings, as: Settings

  @app "monitoring_apiserver"

  resource(:config_map_battery_kube_prometheus_st_apiserver, config) do
    namespace = Settings.namespace(config)
    data = %{"apiserver.json" => get_resource(:apiserver_json)}

    B.build_resource(:config_map)
    |> B.name("battery-kube-prometheus-st-apiserver")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("grafana_dashboard", "1")
    |> B.data(data)
  end

  resource(:prometheus_rule_battery_kube_st_kube_apiserver_availability_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-prometheus-st-kube-apiserver-availability.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "groups" => [
        %{
          "interval" => "3m",
          "name" => "kube-apiserver-availability.rules",
          "rules" => [
            %{
              "expr" =>
                "avg_over_time(code_verb:apiserver_request_total:increase1h[30d]) * 24 * 30",
              "record" => "code_verb:apiserver_request_total:increase30d"
            },
            %{
              "expr" =>
                "sum by (cluster, code) (code_verb:apiserver_request_total:increase30d{verb=~\"LIST|GET\"})",
              "labels" => %{"verb" => "read"},
              "record" => "code:apiserver_request_total:increase30d"
            },
            %{
              "expr" =>
                "sum by (cluster, code) (code_verb:apiserver_request_total:increase30d{verb=~\"POST|PUT|PATCH|DELETE\"})",
              "labels" => %{"verb" => "write"},
              "record" => "code:apiserver_request_total:increase30d"
            },
            %{
              "expr" =>
                "sum by (cluster, verb, scope) (increase(apiserver_request_slo_duration_seconds_count[1h]))",
              "record" =>
                "cluster_verb_scope:apiserver_request_slo_duration_seconds_count:increase1h"
            },
            %{
              "expr" =>
                "sum by (cluster, verb, scope) (avg_over_time(cluster_verb_scope:apiserver_request_slo_duration_seconds_count:increase1h[30d]) * 24 * 30)",
              "record" =>
                "cluster_verb_scope:apiserver_request_slo_duration_seconds_count:increase30d"
            },
            %{
              "expr" =>
                "sum by (cluster, verb, scope, le) (increase(apiserver_request_slo_duration_seconds_bucket[1h]))",
              "record" =>
                "cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase1h"
            },
            %{
              "expr" =>
                "sum by (cluster, verb, scope, le) (avg_over_time(cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase1h[30d]) * 24 * 30)",
              "record" =>
                "cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d"
            },
            %{
              "expr" =>
                "1 - (\n  (\n    # write too slow\n    sum by (cluster) (cluster_verb_scope:apiserver_request_slo_duration_seconds_count:increase30d{verb=~\"POST|PUT|PATCH|DELETE\"})\n    -\n    sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"POST|PUT|PATCH|DELETE\",le=\"1\"})\n  ) +\n  (\n    # read too slow\n    sum by (cluster) (cluster_verb_scope:apiserver_request_slo_duration_seconds_count:increase30d{verb=~\"LIST|GET\"})\n    -\n    (\n      (\n        sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"LIST|GET\",scope=~\"resource|\",le=\"1\"})\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"LIST|GET\",scope=\"namespace\",le=\"5\"})\n      +\n      sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"LIST|GET\",scope=\"cluster\",le=\"30\"})\n    )\n  ) +\n  # errors\n  sum by (cluster) (code:apiserver_request_total:increase30d{code=~\"5..\"} or vector(0))\n)\n/\nsum by (cluster) (code:apiserver_request_total:increase30d)",
              "labels" => %{"verb" => "all"},
              "record" => "apiserver_request:availability30d"
            },
            %{
              "expr" =>
                "1 - (\n  sum by (cluster) (cluster_verb_scope:apiserver_request_slo_duration_seconds_count:increase30d{verb=~\"LIST|GET\"})\n  -\n  (\n    # too slow\n    (\n      sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"LIST|GET\",scope=~\"resource|\",le=\"1\"})\n      or\n      vector(0)\n    )\n    +\n    sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"LIST|GET\",scope=\"namespace\",le=\"5\"})\n    +\n    sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"LIST|GET\",scope=\"cluster\",le=\"30\"})\n  )\n  +\n  # errors\n  sum by (cluster) (code:apiserver_request_total:increase30d{verb=\"read\",code=~\"5..\"} or vector(0))\n)\n/\nsum by (cluster) (code:apiserver_request_total:increase30d{verb=\"read\"})",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:availability30d"
            },
            %{
              "expr" =>
                "1 - (\n  (\n    # too slow\n    sum by (cluster) (cluster_verb_scope:apiserver_request_slo_duration_seconds_count:increase30d{verb=~\"POST|PUT|PATCH|DELETE\"})\n    -\n    sum by (cluster) (cluster_verb_scope_le:apiserver_request_slo_duration_seconds_bucket:increase30d{verb=~\"POST|PUT|PATCH|DELETE\",le=\"1\"})\n  )\n  +\n  # errors\n  sum by (cluster) (code:apiserver_request_total:increase30d{verb=\"write\",code=~\"5..\"} or vector(0))\n)\n/\nsum by (cluster) (code:apiserver_request_total:increase30d{verb=\"write\"})",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:availability30d"
            },
            %{
              "expr" =>
                "sum by (cluster,code,resource) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[5m]))",
              "labels" => %{"verb" => "read"},
              "record" => "code_resource:apiserver_request_total:rate5m"
            },
            %{
              "expr" =>
                "sum by (cluster,code,resource) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[5m]))",
              "labels" => %{"verb" => "write"},
              "record" => "code_resource:apiserver_request_total:rate5m"
            },
            %{
              "expr" =>
                "sum by (cluster, code, verb) (increase(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET|POST|PUT|PATCH|DELETE\",code=~\"2..\"}[1h]))",
              "record" => "code_verb:apiserver_request_total:increase1h"
            },
            %{
              "expr" =>
                "sum by (cluster, code, verb) (increase(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET|POST|PUT|PATCH|DELETE\",code=~\"3..\"}[1h]))",
              "record" => "code_verb:apiserver_request_total:increase1h"
            },
            %{
              "expr" =>
                "sum by (cluster, code, verb) (increase(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET|POST|PUT|PATCH|DELETE\",code=~\"4..\"}[1h]))",
              "record" => "code_verb:apiserver_request_total:increase1h"
            },
            %{
              "expr" =>
                "sum by (cluster, code, verb) (increase(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET|POST|PUT|PATCH|DELETE\",code=~\"5..\"}[1h]))",
              "record" => "code_verb:apiserver_request_total:increase1h"
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_battery_kube_st_kube_apiserver_burnrate_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-prometheus-st-kube-apiserver-burnrate.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "kube-prometheus-stack")
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kube-apiserver-burnrate.rules",
          "rules" => [
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[1d]))\n    -\n    (\n      (\n        sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=~\"resource|\",le=\"1\"}[1d]))\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"namespace\",le=\"5\"}[1d]))\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"cluster\",le=\"30\"}[1d]))\n    )\n  )\n  +\n  # errors\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\",code=~\"5..\"}[1d]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[1d]))",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:burnrate1d"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[1h]))\n    -\n    (\n      (\n        sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=~\"resource|\",le=\"1\"}[1h]))\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"namespace\",le=\"5\"}[1h]))\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"cluster\",le=\"30\"}[1h]))\n    )\n  )\n  +\n  # errors\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\",code=~\"5..\"}[1h]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[1h]))",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:burnrate1h"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[2h]))\n    -\n    (\n      (\n        sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=~\"resource|\",le=\"1\"}[2h]))\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"namespace\",le=\"5\"}[2h]))\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"cluster\",le=\"30\"}[2h]))\n    )\n  )\n  +\n  # errors\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\",code=~\"5..\"}[2h]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[2h]))",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:burnrate2h"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[30m]))\n    -\n    (\n      (\n        sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=~\"resource|\",le=\"1\"}[30m]))\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"namespace\",le=\"5\"}[30m]))\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"cluster\",le=\"30\"}[30m]))\n    )\n  )\n  +\n  # errors\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\",code=~\"5..\"}[30m]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[30m]))",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:burnrate30m"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[3d]))\n    -\n    (\n      (\n        sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=~\"resource|\",le=\"1\"}[3d]))\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"namespace\",le=\"5\"}[3d]))\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"cluster\",le=\"30\"}[3d]))\n    )\n  )\n  +\n  # errors\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\",code=~\"5..\"}[3d]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[3d]))",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:burnrate3d"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[5m]))\n    -\n    (\n      (\n        sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=~\"resource|\",le=\"1\"}[5m]))\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"namespace\",le=\"5\"}[5m]))\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"cluster\",le=\"30\"}[5m]))\n    )\n  )\n  +\n  # errors\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\",code=~\"5..\"}[5m]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[5m]))",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:burnrate5m"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[6h]))\n    -\n    (\n      (\n        sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=~\"resource|\",le=\"1\"}[6h]))\n        or\n        vector(0)\n      )\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"namespace\",le=\"5\"}[6h]))\n      +\n      sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\",scope=\"cluster\",le=\"30\"}[6h]))\n    )\n  )\n  +\n  # errors\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\",code=~\"5..\"}[6h]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"LIST|GET\"}[6h]))",
              "labels" => %{"verb" => "read"},
              "record" => "apiserver_request:burnrate6h"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[1d]))\n    -\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\",le=\"1\"}[1d]))\n  )\n  +\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",code=~\"5..\"}[1d]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[1d]))",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:burnrate1d"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[1h]))\n    -\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\",le=\"1\"}[1h]))\n  )\n  +\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",code=~\"5..\"}[1h]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[1h]))",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:burnrate1h"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[2h]))\n    -\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\",le=\"1\"}[2h]))\n  )\n  +\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",code=~\"5..\"}[2h]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[2h]))",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:burnrate2h"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[30m]))\n    -\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\",le=\"1\"}[30m]))\n  )\n  +\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",code=~\"5..\"}[30m]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[30m]))",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:burnrate30m"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[3d]))\n    -\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\",le=\"1\"}[3d]))\n  )\n  +\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",code=~\"5..\"}[3d]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[3d]))",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:burnrate3d"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[5m]))\n    -\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\",le=\"1\"}[5m]))\n  )\n  +\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",code=~\"5..\"}[5m]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[5m]))",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:burnrate5m"
            },
            %{
              "expr" =>
                "(\n  (\n    # too slow\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_count{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[6h]))\n    -\n    sum by (cluster) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\",le=\"1\"}[6h]))\n  )\n  +\n  sum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",code=~\"5..\"}[6h]))\n)\n/\nsum by (cluster) (rate(apiserver_request_total{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\"}[6h]))",
              "labels" => %{"verb" => "write"},
              "record" => "apiserver_request:burnrate6h"
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_battery_kube_st_kube_apiserver_histogram_rules, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-prometheus-st-kube-apiserver-histogram.rules")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "kube-prometheus-stack")
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kube-apiserver-histogram.rules",
          "rules" => [
            %{
              "expr" =>
                "histogram_quantile(0.99, sum by (cluster, le, resource) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"LIST|GET\",subresource!~\"proxy|attach|log|exec|portforward\"}[5m]))) > 0",
              "labels" => %{"quantile" => "0.99", "verb" => "read"},
              "record" =>
                "cluster_quantile:apiserver_request_slo_duration_seconds:histogram_quantile"
            },
            %{
              "expr" =>
                "histogram_quantile(0.99, sum by (cluster, le, resource) (rate(apiserver_request_slo_duration_seconds_bucket{job=\"apiserver\",verb=~\"POST|PUT|PATCH|DELETE\",subresource!~\"proxy|attach|log|exec|portforward\"}[5m]))) > 0",
              "labels" => %{"quantile" => "0.99", "verb" => "write"},
              "record" =>
                "cluster_quantile:apiserver_request_slo_duration_seconds:histogram_quantile"
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_battery_kube_st_kube_apiserver_slos, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-prometheus-st-kube-apiserver-slos")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "kube-prometheus-stack")
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kube-apiserver-slos",
          "rules" => [
            %{
              "alert" => "KubeAPIErrorBudgetBurn",
              "annotations" => %{
                "description" => "The API server is burning too much error budget.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeapierrorbudgetburn",
                "summary" => "The API server is burning too much error budget."
              },
              "expr" =>
                "sum(apiserver_request:burnrate1h) > (14.40 * 0.01000)\nand\nsum(apiserver_request:burnrate5m) > (14.40 * 0.01000)",
              "for" => "2m",
              "labels" => %{"long" => "1h", "severity" => "critical", "short" => "5m"}
            },
            %{
              "alert" => "KubeAPIErrorBudgetBurn",
              "annotations" => %{
                "description" => "The API server is burning too much error budget.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeapierrorbudgetburn",
                "summary" => "The API server is burning too much error budget."
              },
              "expr" =>
                "sum(apiserver_request:burnrate6h) > (6.00 * 0.01000)\nand\nsum(apiserver_request:burnrate30m) > (6.00 * 0.01000)",
              "for" => "15m",
              "labels" => %{"long" => "6h", "severity" => "critical", "short" => "30m"}
            },
            %{
              "alert" => "KubeAPIErrorBudgetBurn",
              "annotations" => %{
                "description" => "The API server is burning too much error budget.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeapierrorbudgetburn",
                "summary" => "The API server is burning too much error budget."
              },
              "expr" =>
                "sum(apiserver_request:burnrate1d) > (3.00 * 0.01000)\nand\nsum(apiserver_request:burnrate2h) > (3.00 * 0.01000)",
              "for" => "1h",
              "labels" => %{"long" => "1d", "severity" => "warning", "short" => "2h"}
            },
            %{
              "alert" => "KubeAPIErrorBudgetBurn",
              "annotations" => %{
                "description" => "The API server is burning too much error budget.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeapierrorbudgetburn",
                "summary" => "The API server is burning too much error budget."
              },
              "expr" =>
                "sum(apiserver_request:burnrate3d) > (1.00 * 0.01000)\nand\nsum(apiserver_request:burnrate6h) > (1.00 * 0.01000)",
              "for" => "3h",
              "labels" => %{"long" => "3d", "severity" => "warning", "short" => "6h"}
            }
          ]
        }
      ]
    })
  end

  resource(:prometheus_rule_battery_kube_st_kubernetes_system_apiserver, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:prometheus_rule)
    |> B.name("battery-kube-prometheus-st-kubernetes-system-apiserver")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.label("app", "kube-prometheus-stack")
    |> B.spec(%{
      "groups" => [
        %{
          "name" => "kubernetes-system-apiserver",
          "rules" => [
            %{
              "alert" => "KubeClientCertificateExpiration",
              "annotations" => %{
                "description" =>
                  "A client certificate used to authenticate to kubernetes apiserver is expiring in less than 7.0 days.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeclientcertificateexpiration",
                "summary" => "Client certificate is about to expire."
              },
              "expr" =>
                "apiserver_client_certificate_expiration_seconds_count{job=\"apiserver\"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job=\"apiserver\"}[5m]))) < 604800",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeClientCertificateExpiration",
              "annotations" => %{
                "description" =>
                  "A client certificate used to authenticate to kubernetes apiserver is expiring in less than 24.0 hours.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeclientcertificateexpiration",
                "summary" => "Client certificate is about to expire."
              },
              "expr" =>
                "apiserver_client_certificate_expiration_seconds_count{job=\"apiserver\"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job=\"apiserver\"}[5m]))) < 86400",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "KubeAggregatedAPIErrors",
              "annotations" => %{
                "description" =>
                  "Kubernetes aggregated API {{ $labels.name }}/{{ $labels.namespace }} has reported errors. It has appeared unavailable {{ $value | humanize }} times averaged over the past 10m.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeaggregatedapierrors",
                "summary" => "Kubernetes aggregated API has reported errors."
              },
              "expr" =>
                "sum by(name, namespace, cluster)(increase(aggregator_unavailable_apiservice_total[10m])) > 4",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeAggregatedAPIDown",
              "annotations" => %{
                "description" =>
                  "Kubernetes aggregated API {{ $labels.name }}/{{ $labels.namespace }} has been only {{ $value | humanize }}% available over the last 10m.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeaggregatedapidown",
                "summary" => "Kubernetes aggregated API is down."
              },
              "expr" =>
                "(1 - max by(name, namespace, cluster)(avg_over_time(aggregator_unavailable_apiservice[10m]))) * 100 < 85",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            },
            %{
              "alert" => "KubeAPIDown",
              "annotations" => %{
                "description" => "KubeAPI has disappeared from Prometheus target discovery.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeapidown",
                "summary" => "Target disappeared from Prometheus target discovery."
              },
              "expr" => "absent(up{job=\"apiserver\"} == 1)",
              "for" => "15m",
              "labels" => %{"severity" => "critical"}
            },
            %{
              "alert" => "KubeAPITerminatedRequests",
              "annotations" => %{
                "description" =>
                  "The kubernetes apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests.",
                "runbook_url" =>
                  "https://runbooks.prometheus-operator.dev/runbooks/kubernetes/kubeapiterminatedrequests",
                "summary" =>
                  "The kubernetes apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests."
              },
              "expr" =>
                "sum(rate(apiserver_request_terminations_total{job=\"apiserver\"}[10m]))  / (  sum(rate(apiserver_request_total{job=\"apiserver\"}[10m])) + sum(rate(apiserver_request_terminations_total{job=\"apiserver\"}[10m])) ) > 0.20",
              "for" => "5m",
              "labels" => %{"severity" => "warning"}
            }
          ]
        }
      ]
    })
  end

  resource(:service_monitor_battery_kube_prometheus_st_apiserver, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_monitor)
    |> B.name("battery-kube-prometheus-st-apiserver")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(%{
      "endpoints" => [
        %{
          "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
          "metricRelabelings" => [
            %{
              "action" => "drop",
              "regex" =>
                "apiserver_request_duration_seconds_bucket;(0.15|0.2|0.3|0.35|0.4|0.45|0.6|0.7|0.8|0.9|1.25|1.5|1.75|2|3|3.5|4|4.5|6|7|8|9|15|25|40|50)",
              "sourceLabels" => ["__name__", "le"]
            }
          ],
          "port" => "https",
          "scheme" => "https",
          "tlsConfig" => %{
            "caFile" => "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt",
            "insecureSkipVerify" => false,
            "serverName" => "kubernetes"
          }
        }
      ],
      "jobLabel" => "component",
      "namespaceSelector" => %{"matchNames" => ["default"]},
      "selector" => %{"matchLabels" => %{"component" => "apiserver", "provider" => "kubernetes"}}
    })
  end
end
