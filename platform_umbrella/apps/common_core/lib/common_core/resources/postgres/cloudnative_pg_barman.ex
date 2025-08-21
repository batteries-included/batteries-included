defmodule CommonCore.Resources.CloudnativePGBarman do
  @moduledoc false
  use CommonCore.IncludeResource,
    objectstores_barmancloud_cnpg_io: "priv/manifests/barman_cloud/objectstores_barmancloud_cnpg_io.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "barman-cloud"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  @server_port 9090

  multi_resource(:crds_barmancloud) do
    Enum.flat_map(@included_resources, &(&1 |> get_resource() |> YamlElixir.read_all_from_string!()))
  end

  resource(:certmanager_certificate_barman_cloud_client, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("commonName", "barman-cloud-client")
      |> Map.put("duration", "2160h")
      |> Map.put("isCA", false)
      |> Map.put("issuerRef", %{"group" => "cert-manager.io", "kind" => "ClusterIssuer", "name" => "battery-ca"})
      |> Map.put("renewBefore", "360h")
      |> Map.put("secretName", "barman-cloud-client-tls")
      |> Map.put("usages", ["client auth"])

    :certmanager_certificate
    |> B.build_resource()
    |> B.name("barman-cloud-client")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:certmanager_certificate_barman_cloud_server, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("commonName", "barman-cloud")
      |> Map.put("dnsNames", ["barman-cloud"])
      |> Map.put("duration", "2160h")
      |> Map.put("isCA", false)
      |> Map.put("issuerRef", %{"group" => "cert-manager.io", "kind" => "ClusterIssuer", "name" => "battery-ca"})
      |> Map.put("renewBefore", "360h")
      |> Map.put("secretName", "barman-cloud-server-tls")
      |> Map.put("usages", ["server auth"])

    :certmanager_certificate
    |> B.build_resource()
    |> B.name("barman-cloud-server")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:cluster_role_binding_metrics_auth_rolebinding, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("barman:metrics-auth-rolebinding")
    |> B.role_ref(B.build_cluster_role_ref("barman:metrics-auth-role"))
    |> B.subject(B.build_service_account("plugin-barman-cloud", namespace))
  end

  resource(:cluster_role_binding_plugin_barman_cloud, _battery, state) do
    namespace = core_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("plugin-barman-cloud-binding")
    |> B.component_labels("plugin-barman-cloud")
    |> B.role_ref(B.build_cluster_role_ref("plugin-barman-cloud"))
    |> B.subject(B.build_service_account("plugin-barman-cloud", namespace))
  end

  resource(:cluster_role_metrics_auth) do
    rules = [
      %{
        "apiGroups" => ["authentication.k8s.io"],
        "resources" => ["tokenreviews"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => ["authorization.k8s.io"],
        "resources" => ["subjectaccessreviews"],
        "verbs" => ["create"]
      }
    ]

    :cluster_role |> B.build_resource() |> B.name("barman:metrics-auth-role") |> B.rules(rules)
  end

  resource(:cluster_role_metrics_reader) do
    rules = [%{"nonResourceURLs" => ["/metrics"], "verbs" => ["get"]}]
    :cluster_role |> B.build_resource() |> B.name("barman:metrics-reader") |> B.rules(rules)
  end

  resource(:cluster_role_objectstore_editor) do
    rules = [
      %{
        "apiGroups" => ["barmancloud.cnpg.io"],
        "resources" => ["objectstores"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["barmancloud.cnpg.io"],
        "resources" => ["objectstores/status"],
        "verbs" => ["get"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("barman:objectstore-editor-role")
    |> B.component_labels("plugin-barman-cloud")
    |> B.rules(rules)
  end

  resource(:cluster_role_objectstore_viewer) do
    rules = [
      %{
        "apiGroups" => ["barmancloud.cnpg.io"],
        "resources" => ["objectstores"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["barmancloud.cnpg.io"],
        "resources" => ["objectstores/status"],
        "verbs" => ["get"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("barman:objectstore-viewer-role")
    |> B.component_labels("plugin-barman-cloud")
    |> B.rules(rules)
  end

  resource(:cluster_role_plugin_barman_cloud) do
    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => ["barmancloud.cnpg.io"],
        "resources" => ["objectstores"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{
        "apiGroups" => ["barmancloud.cnpg.io"],
        "resources" => ["objectstores/finalizers"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["barmancloud.cnpg.io"],
        "resources" => ["objectstores/status"],
        "verbs" => ["get", "patch", "update"]
      },
      %{
        "apiGroups" => ["postgresql.cnpg.io"],
        "resources" => ["backups"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["postgresql.cnpg.io"],
        "resources" => ["clusters/finalizers"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["rolebindings", "roles"],
        "verbs" => ["create", "get", "list", "patch", "update", "watch"]
      }
    ]

    :cluster_role |> B.build_resource() |> B.name("plugin-barman-cloud") |> B.rules(rules)
  end

  resource(:deployment_barman_cloud, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{"labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}})
      |> Map.put("spec", %{
        "containers" => [
          %{
            "args" => [
              "operator",
              "--server-cert=/server/tls.crt",
              "--server-key=/server/tls.key",
              "--client-cert=/client/ca.crt",
              "--server-address=:#{@server_port}",
              "--leader-elect",
              "--log-level=trace"
            ],
            "env" => [
              %{
                "name" => "SIDECAR_IMAGE",
                "value" => battery.config.barman_plugin_sidecar_image
              }
            ],
            "image" => battery.config.barman_plugin_image,
            "name" => "barman-cloud",
            "ports" => [%{"containerPort" => @server_port, "protocol" => "TCP"}],
            "readinessProbe" => %{
              "initialDelaySeconds" => 10,
              "periodSeconds" => 10,
              "tcpSocket" => %{"port" => @server_port}
            },
            "resources" => %{},
            "securityContext" => %{
              "allowPrivilegeEscalation" => false,
              "capabilities" => %{"drop" => ["ALL"]},
              "readOnlyRootFilesystem" => true,
              "runAsGroup" => 10_001,
              "runAsUser" => 10_001,
              "seccompProfile" => %{"type" => "RuntimeDefault"}
            },
            "volumeMounts" => [
              %{"mountPath" => "/server", "name" => "server"},
              %{"mountPath" => "/client", "name" => "client"}
            ]
          }
        ],
        "securityContext" => %{
          "runAsNonRoot" => true,
          "seccompProfile" => %{"type" => "RuntimeDefault"}
        },
        "serviceAccountName" => "plugin-barman-cloud",
        "volumes" => [
          %{"name" => "server", "secret" => %{"secretName" => "barman-cloud-server-tls"}},
          %{"name" => "client", "secret" => %{"secretName" => "barman-cloud-client-tls"}}
        ]
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> Map.put("strategy", %{"type" => "Recreate"})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("barman-cloud")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:role_binding_leader_election_rolebinding, _battery, state) do
    namespace = core_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("barman:leader-election-rolebinding")
    |> B.namespace(namespace)
    |> B.component_labels("plugin-barman-cloud")
    |> B.role_ref(B.build_role_ref("barman:leader-election-role"))
    |> B.subject(B.build_service_account("plugin-barman-cloud", namespace))
  end

  resource(:role_leader_election, _battery, state) do
    namespace = core_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("barman:leader-election-role")
    |> B.namespace(namespace)
    |> B.component_labels("plugin-barman-cloud")
    |> B.rules(rules)
  end

  resource(:service_account_plugin_barman_cloud, _battery, state) do
    namespace = core_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("plugin-barman-cloud")
    |> B.namespace(namespace)
    |> B.component_labels("plugin-barman-cloud")
  end

  resource(:service_barman_cloud, _battery, state) do
    namespace = core_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [%{"port" => @server_port, "protocol" => "TCP", "targetPort" => @server_port}])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("barman-cloud")
    |> B.namespace(namespace)
    |> B.label("cnpg.io/pluginName", "barman-cloud.cloudnative-pg.io")
    |> B.annotations(%{
      "cnpg.io/pluginPort" => "#{@server_port}",
      "cnpg.io/pluginClientSecret" => "barman-cloud-client-tls",
      "cnpg.io/pluginServerSecret" => "barman-cloud-server-tls"
    })
    |> B.spec(spec)
  end
end
