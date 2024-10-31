defmodule CommonCore.Resources.IstioIngress do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-ingressgateway"

  import CommonCore.Resources.MapUtils
  import CommonCore.Resources.ProxyUtils, only: [sanitize: 1]
  import CommonCore.StateSummary.Batteries, only: [hosts_by_battery_type: 1]
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Core
  alias CommonCore.StateSummary.TraditionalServices

  resource(:service_ingressgateway, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "status-port", "port" => 15_021, "protocol" => "TCP", "targetPort" => 15_021},
        %{"name" => "http2", "port" => 80, "protocol" => "TCP", "targetPort" => 8080},
        %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => 8443}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "istio" => "ingressgateway"})
      |> Map.put("type", "LoadBalancer")

    :service
    |> B.build_resource()
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
    |> add_public_lb_annotations(state)
  end

  defp add_public_lb_annotations(config, state) do
    aws_lb_installed? = Batteries.batteries_installed?(state, :aws_load_balancer_controller)
    cluster_name = Core.config_field(state, :cluster_name)

    annotations =
      if aws_lb_installed? do
        battery = Batteries.by_type(state).aws_load_balancer_controller

        tags =
          Enum.join(
            [
              "batteriesincl.com/managed=true",
              "batteriesincl.com/environment=organization/bi/#{cluster_name}"
            ],
            ","
          )

        %{
          "service.beta.kubernetes.io/aws-load-balancer-scheme" => "internet-facing",
          # the advantage of the AWS VPC CNI is that each pod has an IP, use those instead of the instances
          # the controller will make sure that the LB is updated as pods come and go
          "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" => "ip",
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" => "true",
          "service.beta.kubernetes.io/aws-load-balancer-name" => "#{cluster_name}-ingress",
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" => tags
        }
        |> maybe_put_lazy(
          battery.config.subnets != nil,
          "service.beta.kubernetes.io/aws-load-balancer-subnets",
          fn _ -> battery.config.subnets |> Enum.sort() |> Enum.join(",") end
        )
        |> maybe_put_lazy(
          battery.config.eip_allocations != nil,
          "service.beta.kubernetes.io/aws-load-balancer-eip-allocations",
          fn _ -> battery.config.eip_allocations |> Enum.sort() |> Enum.join(",") end
        )
      else
        %{}
      end

    B.annotations(config, annotations)
  end

  resource(:service_account_ingressgateway, _battery, state) do
    namespace = istio_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("istio-ingressgateway-service-account")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
  end

  resource(:role_ingressgateway_sds, _battery, state) do
    namespace = istio_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("istio-ingressgateway-sds")
    |> B.namespace(namespace)
    |> B.label("istio.io/rev", "default")
    |> B.label("istio", "ingressgateway")
    |> B.rules(rules)
  end

  resource(:role_binding_ingressgateway_sds, _battery, state) do
    namespace = istio_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("istio-ingressgateway-sds")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.role_ref(B.build_role_ref("istio-ingressgateway-sds"))
    |> B.subject(B.build_service_account("istio-ingressgateway-service-account", namespace))
  end

  resource(:deployment_ingressgateway, battery, state) do
    namespace = istio_namespace(state)

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "annotations" => %{
            "istio.io/rev" => "default",
            "prometheus.io/path" => "/stats/prometheus",
            "prometheus.io/port" => "15020",
            "prometheus.io/scrape" => "true"
          },
          "labels" => %{
            "battery/managed" => "true",
            "istio" => "ingressgateway",
            "istio.io/rev" => "default",
            "service.istio.io/canonical-name" => "istio-ingressgateway",
            "service.istio.io/canonical-revision" => "latest",
            "sidecar.istio.io/inject" => "false"
          }
        }
      )
      |> Map.put(
        "spec",
        %{
          "containers" => [
            %{
              "args" => [
                "proxy",
                "router",
                "--domain",
                "$(POD_NAMESPACE).svc.cluster.local",
                "--proxyLogLevel=warning",
                "--proxyComponentLogLevel=misc:error",
                "--log_output_level=default:info"
              ],
              "env" => [
                %{"name" => "JWT_POLICY", "value" => "third-party-jwt"},
                %{"name" => "PILOT_CERT_PROVIDER", "value" => "istiod"},
                %{"name" => "CA_ADDR", "value" => "istiod.battery-istio.svc:15012"},
                %{
                  "name" => "NODE_NAME",
                  "valueFrom" => %{"fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "spec.nodeName"}}
                },
                %{
                  "name" => "POD_NAME",
                  "valueFrom" => %{"fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.name"}}
                },
                %{
                  "name" => "POD_NAMESPACE",
                  "valueFrom" => %{"fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "metadata.namespace"}}
                },
                %{
                  "name" => "INSTANCE_IP",
                  "valueFrom" => %{"fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "status.podIP"}}
                },
                %{
                  "name" => "HOST_IP",
                  "valueFrom" => %{"fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "status.hostIP"}}
                },
                %{"name" => "ISTIO_CPU_LIMIT", "valueFrom" => %{"resourceFieldRef" => %{"resource" => "limits.cpu"}}},
                %{
                  "name" => "SERVICE_ACCOUNT",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.serviceAccountName"}}
                },
                %{"name" => "ISTIO_META_WORKLOAD_NAME", "value" => "istio-ingressgateway"},
                %{
                  "name" => "ISTIO_META_OWNER",
                  "value" => "kubernetes://apis/apps/v1/namespaces/battery-istio/deployments/istio-ingressgateway"
                },
                %{"name" => "ISTIO_META_MESH_ID", "value" => "cluster.local"},
                %{"name" => "TRUST_DOMAIN", "value" => "cluster.local"},
                %{"name" => "ISTIO_META_UNPRIVILEGED_POD", "value" => "true"},
                %{"name" => "ISTIO_META_CLUSTER_ID", "value" => "Kubernetes"},
                %{"name" => "ISTIO_META_NODE_NAME", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}}
              ],
              "image" => battery.config.proxy_image,
              "name" => "istio-proxy",
              "ports" => [
                %{"containerPort" => 15_021, "protocol" => "TCP"},
                %{"containerPort" => 8080, "protocol" => "TCP"},
                %{"containerPort" => 8443, "protocol" => "TCP"},
                %{"containerPort" => 15_090, "name" => "http-envoy-prom", "protocol" => "TCP"}
              ],
              "readinessProbe" => %{
                "failureThreshold" => 30,
                "httpGet" => %{"path" => "/healthz/ready", "port" => 15_021, "scheme" => "HTTP"},
                "initialDelaySeconds" => 1,
                "periodSeconds" => 2,
                "successThreshold" => 1,
                "timeoutSeconds" => 1
              },
              "resources" => %{
                "limits" => %{"cpu" => "2000m", "memory" => "1024Mi"},
                "requests" => %{"cpu" => "100m", "memory" => "128Mi"}
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "capabilities" => %{"drop" => ["ALL"]},
                "privileged" => false,
                "readOnlyRootFilesystem" => true
              },
              "volumeMounts" => [
                %{"mountPath" => "/var/run/secrets/workload-spiffe-uds", "name" => "workload-socket"},
                %{"mountPath" => "/var/run/secrets/credential-uds", "name" => "credential-socket"},
                %{"mountPath" => "/var/run/secrets/workload-spiffe-credentials", "name" => "workload-certs"},
                %{"mountPath" => "/etc/istio/proxy", "name" => "istio-envoy"},
                %{"mountPath" => "/etc/istio/config", "name" => "config-volume"},
                %{"mountPath" => "/var/run/secrets/istio", "name" => "istiod-ca-cert"},
                %{"mountPath" => "/var/run/secrets/tokens", "name" => "istio-token", "readOnly" => true},
                %{"mountPath" => "/var/lib/istio/data", "name" => "istio-data"},
                %{"mountPath" => "/etc/istio/pod", "name" => "podinfo"},
                %{"mountPath" => "/etc/istio/ingressgateway-certs", "name" => "ingressgateway-certs", "readOnly" => true},
                %{
                  "mountPath" => "/etc/istio/ingressgateway-ca-certs",
                  "name" => "ingressgateway-ca-certs",
                  "readOnly" => true
                }
              ]
            }
          ],
          "securityContext" => %{"runAsGroup" => 1337, "runAsNonRoot" => true, "runAsUser" => 1337},
          "serviceAccountName" => "istio-ingressgateway-service-account",
          "volumes" => [
            %{"emptyDir" => %{}, "name" => "workload-socket"},
            %{"emptyDir" => %{}, "name" => "credential-socket"},
            %{"emptyDir" => %{}, "name" => "workload-certs"},
            %{"configMap" => %{"name" => "istio-ca-root-cert"}, "name" => "istiod-ca-cert"},
            %{
              "downwardAPI" => %{
                "items" => [
                  %{"fieldRef" => %{"fieldPath" => "metadata.labels"}, "path" => "labels"},
                  %{"fieldRef" => %{"fieldPath" => "metadata.annotations"}, "path" => "annotations"}
                ]
              },
              "name" => "podinfo"
            },
            %{"emptyDir" => %{}, "name" => "istio-envoy"},
            %{"emptyDir" => %{}, "name" => "istio-data"},
            %{
              "name" => "istio-token",
              "projected" => %{
                "sources" => [
                  %{
                    "serviceAccountToken" => %{
                      "audience" => "istio-ca",
                      "expirationSeconds" => 43_200,
                      "path" => "istio-token"
                    }
                  }
                ]
              }
            },
            %{"configMap" => %{"name" => "istio", "optional" => true}, "name" => "config-volume"},
            %{
              "name" => "ingressgateway-certs",
              "secret" => %{"optional" => true, "secretName" => "istio-ingressgateway-certs"}
            },
            %{
              "name" => "ingressgateway-ca-certs",
              "secret" => %{"optional" => true, "secretName" => "istio-ingressgateway-ca-certs"}
            }
          ]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name, "istio" => "ingressgateway"}})
      |> Map.put("strategy", %{"rollingUpdate" => %{"maxSurge" => "100%", "maxUnavailable" => "25%"}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:horizontal_pod_autoscaler_ingressgateway, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("maxReplicas", 5)
      |> Map.put("metrics", [
        %{
          "resource" => %{"name" => "cpu", "target" => %{"averageUtilization" => 80, "type" => "Utilization"}},
          "type" => "Resource"
        }
      ])
      |> Map.put("minReplicas", 1)
      |> Map.put(
        "scaleTargetRef",
        %{"apiVersion" => "apps/v1", "kind" => "Deployment", "name" => "istio-ingressgateway"}
      )

    :horizontal_pod_autoscaler
    |> B.build_resource()
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:pod_disruption_budget_ingressgateway, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("minAvailable", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "istio" => "ingressgateway"}}
      )

    :pod_disruption_budget
    |> B.build_resource()
    |> B.name("istio-ingressgateway")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  resource(:gateway, _battery, state) do
    namespace = istio_namespace(state)

    ssl_enabled? = CommonCore.StateSummary.SSL.ssl_enabled?(state)

    battery_servers =
      state
      |> hosts_by_battery_type()
      |> Enum.flat_map(fn {type, hosts} -> build_battery_servers(type, hosts, ssl_enabled?) end)

    traditional_service_servers =
      state
      |> TraditionalServices.external_hosts_and_ports_by_name()
      |> Enum.flat_map(fn {_, {host, ports}} -> build_server_for_traditional_service(host, ports, ssl_enabled?) end)

    servers = battery_servers ++ traditional_service_servers

    spec = %{
      selector: %{istio: "ingressgateway"},
      servers: servers
    }

    :istio_gateway
    |> B.build_resource()
    |> B.name("ingressgateway")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
    |> F.require_non_empty(servers)
  end

  # This ingress class is used by e.g. cert-manager to present HTTP01 challenges
  resource(:istio_ingress_class) do
    spec = %{"controller" => "istio.io/ingress-controller"}

    :ingress_class
    |> B.build_resource()
    |> B.name("istio")
    |> B.spec(spec)
  end

  defp build_battery_servers(:forgejo = type, hosts, ssl_enabled?),
    do: [forgejo_ssh_server(hosts)] ++ web_servers(sanitize(type), hosts, ssl_enabled?)

  defp build_battery_servers(type, hosts, ssl_enabled?), do: web_servers(sanitize(type), hosts, ssl_enabled?)

  defp web_servers(type, hosts, true = _ssl_enabled?) do
    [
      %{
        port: %{number: 443, name: "https-#{type}", protocol: "HTTPS"},
        tls: %{mode: "SIMPLE", credentialName: "#{type}-ingress-cert"},
        hosts: hosts
      },
      %{
        port: %{number: 80, name: "http2-#{sanitize(type)}", protocol: "HTTP"},
        hosts: hosts
      }
    ]
  end

  defp web_servers(type, hosts, false = _ssl_enabled?) do
    [
      %{
        port: %{number: 80, name: "http2-#{sanitize(type)}", protocol: "HTTP"},
        hosts: hosts
      }
    ]
  end

  defp forgejo_ssh_server(hosts), do: %{port: %{number: 22, name: "ssh-forgejo", protocol: "TCP"}, hosts: hosts}

  defp build_server_for_traditional_service(_hosts, ports, _ssl_enabled?) when is_nil(ports) or ports == [], do: []

  defp build_server_for_traditional_service(hosts, ports, ssl_enabled?) do
    Enum.flat_map(ports, &build_server_for_traditional_service_port(hosts, &1, ssl_enabled?))
  end

  defp build_server_for_traditional_service_port(hosts, %{protocol: protocol} = port, true = _ssl_enabled?)
       when protocol in [:http, :http2] do
    [
      %{
        port: %{number: 443, name: "#{port.name}-https", protocol: "HTTPS"},
        tls: %{mode: "SIMPLE", credentialName: "traditional-services-ingress-cert"},
        hosts: hosts
      },
      %{
        port: %{number: 80, name: "#{port.name}-http", protocol: normalize_protocol(port.protocol)},
        hosts: hosts
      }
    ]
  end

  defp build_server_for_traditional_service_port(hosts, %{protocol: :tcp} = port, true = _ssl_enabled?) do
    [%{port: %{number: port.number, name: port.name, protocol: "TCP"}, hosts: hosts}]
  end

  defp build_server_for_traditional_service_port(hosts, %{protocol: protocol} = port, false = _ssl_enabled?)
       when protocol in [:http, :http2] do
    [
      %{
        port: %{number: 80, name: port.name, protocol: normalize_protocol(port.protocol)},
        hosts: hosts
      }
    ]
  end

  defp build_server_for_traditional_service_port(hosts, port, false = _ssl_enabled?) do
    [
      %{
        port: %{number: port.number, name: port.name, protocol: normalize_protocol(port.protocol)},
        hosts: hosts
      }
    ]
  end

  defp normalize_protocol(proto), do: String.upcase(Atom.to_string(proto))
end
