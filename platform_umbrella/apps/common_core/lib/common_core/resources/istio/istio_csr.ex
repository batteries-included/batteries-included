defmodule CommonCore.Resources.IstioCsr do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-csr"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:certmanager_certificate_istiod, _battery, state) do
    namespace = istio_namespace(state)

    spec =
      %{}
      |> Map.put("commonName", "istiod.#{namespace}.svc")
      |> Map.put("dnsNames", ["istiod.#{namespace}.svc"])
      # Here we use a duration of 1 hour by default based on NIST 800-204A
      # recommendations (SM-DR13).
      # https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204A.pdf
      # Warning: cert-manager does not allow a duration on Certificates of less
      # than 1 hour.
      |> Map.put("duration", "1h")
      |> Map.put(
        "issuerRef",
        %{"group" => "cert-manager.io", "kind" => "ClusterIssuer", "name" => "battery-ca"}
      )
      |> Map.put("privateKey", %{"algorithm" => "ECDSA", "size" => 256})
      |> Map.put("renewBefore", "30m")
      |> Map.put("revisionHistoryLimit", 1)
      |> Map.put("secretName", "istiod-tls")
      |> Map.put("uris", ["spiffe://cluster.local/ns/#{namespace}/sa/istiod"])

    :certmanager_certificate
    |> B.build_resource()
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.component_labels("istiod")
    |> B.spec(spec)
  end

  resource(:cluster_role_binding_cert_manager_istio_csr, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-istio-csr"))
    |> B.subject(B.build_service_account("cert-manager-istio-csr", namespace))
  end

  resource(:cluster_role_cert_manager_istio_csr) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["get", "list", "create", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.rules(rules)
  end

  resource(:deployment_cert_manager_istio_csr, _battery, state) do
    namespace = base_namespace(state)

    volumes = [
      %{
        "name" => "battery-ca",
        "secret" => %{"defaultMode" => 420, "secretName" => "battery-ca"}
      }
    ]

    containers = [
      %{
        "args" => [
          "--log-level=1",
          "--metrics-port=9402",
          "--readiness-probe-port=6060",
          "--readiness-probe-path=/readyz",
          "--certificate-namespace=#{namespace}",
          "--issuer-name=battery-ca",
          "--issuer-kind=ClusterIssuer",
          "--issuer-group=cert-manager.io",
          "--preserve-certificate-requests=false",
          "--root-ca-file=/var/run/secrets/battery-ca/ca.crt",
          "--serving-certificate-dns-names=cert-manager-istio-csr.#{namespace}.svc",
          "--serving-certificate-duration=1h",
          "--trust-domain=cluster.local",
          "--cluster-id=Kubernetes",
          "--max-client-certificate-duration=1h",
          "--serving-address=0.0.0.0:6443",
          "--serving-certificate-key-size=2048",
          "--leader-election-namespace=#{namespace}"
        ],
        "command" => ["cert-manager-istio-csr"],
        "image" => "quay.io/jetstack/cert-manager-istio-csr:v0.5.0",
        "imagePullPolicy" => "IfNotPresent",
        "name" => "cert-manager-istio-csr",
        "volumeMounts" => [
          %{
            "mountPath" => "/var/run/secrets/battery-ca",
            "name" => "battery-ca",
            "readOnly" => true
          }
        ],
        "ports" => [%{"containerPort" => 6443}, %{"containerPort" => 9402}],
        "readinessProbe" => %{
          "httpGet" => %{"path" => "/readyz", "port" => 6060},
          "initialDelaySeconds" => 3,
          "periodSeconds" => 7
        }
      }
    ]

    template = %{
      "metadata" => %{
        "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
      },
      "spec" => %{
        "containers" => containers,
        "volumes" => volumes,
        "serviceAccountName" => "cert-manager-istio-csr"
      }
    }

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> Map.put("template", template)

    :deployment
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:role_binding_cert_manager_istio_csr, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("cert-manager-istio-csr"))
    |> B.subject(B.build_service_account("cert-manager-istio-csr", namespace))
  end

  resource(:role_cert_manager_istio_csr, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificaterequests"],
        "verbs" => ["get", "list", "create", "update", "delete", "watch"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "create", "update", "watch", "list"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:service_account_cert_manager_istio_csr, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.namespace(namespace)
  end

  resource(:service_cert_manager_istio_csr, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "web", "port" => 443, "protocol" => "TCP", "targetPort" => 6443}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:service_cert_manager_istio_csr_metrics, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "metrics", "port" => 9402, "protocol" => "TCP", "targetPort" => 9402}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr-metrics")
    |> B.namespace(namespace)
    |> B.component_labels("metrics")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:service_monitor_cert_manager_istio_csr, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "interval" => "10s",
          "path" => "/metrics",
          "scrapeTimeout" => "5s",
          "targetPort" => 9402
        }
      ])
      |> Map.put("jobLabel", "cert-manager-istio-csr")
      |> Map.put("namespaceSelector", %{"matchNames" => [namespace]})
      |> Map.put("selector", %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "battery/component" => "metrics"
        }
      })

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("cert-manager-istio-csr")
    |> B.namespace(namespace)
    |> B.component_labels("metrics")
    |> B.label("prometheus", "default")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end
end
