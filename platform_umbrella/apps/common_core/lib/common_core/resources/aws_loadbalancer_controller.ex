defmodule CommonCore.Resources.AwsLoadBalancerController do
  @moduledoc false
  use CommonCore.IncludeResource,
    ingress_class_params: "priv/manifests/aws_load_balancer_controller/ingress_class_params.yaml",
    target_group_bindings: "priv/manifests/aws_load_balancer_controller/target_group_bindings.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "aws-load-balancer-controller"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Core

  resource(:crd_ingress_) do
    YamlElixir.read_all_from_string!(get_resource(:ingress_class_params))
  end

  resource(:crd_nodeclaims_karpenter_sh) do
    YamlElixir.read_all_from_string!(get_resource(:target_group_bindings))
  end

  resource(:cluster_role_binding_aws_load_balancer_controller_rolebinding, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("aws-load-balancer-controller-rolebinding")
    |> B.role_ref(B.build_cluster_role_ref("aws-load-balancer-controller-role"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_aws_load_balancer_controller) do
    rules = [
      %{
        "apiGroups" => ["elbv2.k8s.aws"],
        "resources" => ["targetgroupbindings"],
        "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
      },
      %{"apiGroups" => ["elbv2.k8s.aws"], "resources" => ["ingressclassparams"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["networking.k8s.io"], "resources" => ["ingressclasses"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["", "extensions", "networking.k8s.io"],
        "resources" => ["services", "ingresses"],
        "verbs" => ["get", "list", "patch", "update", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["nodes", "namespaces", "endpoints"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["elbv2.k8s.aws", "", "extensions", "networking.k8s.io"],
        "resources" => ["targetgroupbindings/status", "pods/status", "services/status", "ingresses/status"],
        "verbs" => ["update", "patch"]
      },
      %{"apiGroups" => ["discovery.k8s.io"], "resources" => ["endpointslices"], "verbs" => ["get", "list", "watch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("aws-load-balancer-controller-role")
    |> B.rules(rules)
  end

  resource(:deployment_aws_load_balancer_controller, battery, state) do
    namespace = base_namespace(state)

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "annotations" => %{"prometheus.io/port" => "8080", "prometheus.io/scrape" => "true"},
          "labels" => %{"battery/app" => @app_name, "battery/managed" => "true"}
        }
      )
      |> Map.put(
        "spec",
        %{
          "affinity" => %{
            "podAntiAffinity" => %{
              "preferredDuringSchedulingIgnoredDuringExecution" => [
                %{
                  "podAffinityTerm" => %{
                    "labelSelector" => %{
                      "matchExpressions" => [
                        %{
                          "key" => "battery/app",
                          "operator" => "In",
                          "values" => [@app_name]
                        }
                      ]
                    },
                    "topologyKey" => "kubernetes.io/hostname"
                  },
                  "weight" => 100
                }
              ]
            }
          },
          "containers" => [
            %{
              "args" => ["--cluster-name=#{Core.config_field(state, :cluster_name)}", "--ingress-class=alb"],
              "image" => battery.config.image,
              "imagePullPolicy" => "IfNotPresent",
              "livenessProbe" => %{
                "failureThreshold" => 2,
                "httpGet" => %{"path" => "/healthz", "port" => 61_779, "scheme" => "HTTP"},
                "initialDelaySeconds" => 30,
                "timeoutSeconds" => 10
              },
              "name" => @app_name,
              "ports" => [
                %{"containerPort" => 9443, "name" => "webhook-server", "protocol" => "TCP"},
                %{"containerPort" => 8080, "name" => "metrics-server", "protocol" => "TCP"}
              ],
              "readinessProbe" => %{
                "failureThreshold" => 2,
                "httpGet" => %{"path" => "/readyz", "port" => 61_779, "scheme" => "HTTP"},
                "initialDelaySeconds" => 10,
                "successThreshold" => 1,
                "timeoutSeconds" => 10
              },
              "resources" => %{},
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true
              },
              "volumeMounts" => [
                %{"mountPath" => "/tmp/k8s-webhook-server/serving-certs", "name" => "cert", "readOnly" => true}
              ]
            }
          ],
          "priorityClassName" => "system-cluster-critical",
          "securityContext" => %{"fsGroup" => 65_534},
          "serviceAccountName" => @app_name,
          "terminationGracePeriodSeconds" => 10,
          "tolerations" => [%{"key" => "CriticalAddonsOnly", "operator" => "Exists"}],
          "volumes" => [%{"name" => "cert", "secret" => %{"defaultMode" => 420, "secretName" => "aws-load-balancer-tls"}}]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 2)
      |> Map.put("revisionHistoryLimit", 10)
      |> Map.put("selector", %{"matchLabels" => %{"battery/app" => @app_name}})
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:ingress_class_alb) do
    spec = Map.put(%{}, "controller", "ingress.k8s.aws/alb")
    :ingress_class |> B.build_resource() |> B.name("alb") |> B.spec(spec)
  end

  resource(:ingress_class_params_alb) do
    :ingress_class_params |> B.build_resource() |> B.name("alb")
  end

  resource(:mutating_webhook_config_aws_load_balancer, _battery, state) do
    namespace = base_namespace(state)

    :mutating_webhook_config
    |> B.build_resource()
    |> B.name("aws-load-balancer-webhook")
    |> B.annotation("cert-manager.io/inject-ca-from", "#{namespace}/aws-load-balancer-controller-serving-cert")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "aws-load-balancer-webhook-service",
            "namespace" => namespace,
            "path" => "/mutate-v1-pod"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "mpod.elbv2.k8s.aws",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "elbv2.k8s.aws/pod-readiness-gate-inject", "operator" => "In", "values" => ["enabled"]}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "battery/app", "operator" => "NotIn", "values" => [@app_name]}
          ]
        },
        "rules" => [%{"apiGroups" => [""], "apiVersions" => ["v1"], "operations" => ["CREATE"], "resources" => ["pods"]}],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "aws-load-balancer-webhook-service",
            "namespace" => namespace,
            "path" => "/mutate-v1-service"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "mservice.elbv2.k8s.aws",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "elbv2.k8s.aws/service-webhook", "operator" => "NotIn", "values" => ["disabled"]}
          ]
        },
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "battery/app", "operator" => "NotIn", "values" => [@app_name]}
          ]
        },
        "rules" => [
          %{"apiGroups" => [""], "apiVersions" => ["v1"], "operations" => ["CREATE"], "resources" => ["services"]}
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "aws-load-balancer-webhook-service",
            "namespace" => namespace,
            "path" => "/mutate-elbv2-k8s-aws-v1beta1-targetgroupbinding"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "mtargetgroupbinding.elbv2.k8s.aws",
        "rules" => [
          %{
            "apiGroups" => ["elbv2.k8s.aws"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["targetgroupbindings"]
          }
        ],
        "sideEffects" => "None"
      }
    ])
  end

  resource(:role_binding_aws_load_balancer_controller_leader_election_rolebinding, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("aws-load-balancer-controller-leader-election-rolebinding")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("aws-load-balancer-controller-leader-election-role"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_aws_load_balancer_controller_leader_election, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["create"]},
      %{
        "apiGroups" => [""],
        "resourceNames" => ["aws-load-balancer-controller-leader"],
        "resources" => ["configmaps"],
        "verbs" => ["get", "patch", "update"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create"]},
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => ["aws-load-balancer-controller-leader"],
        "resources" => ["leases"],
        "verbs" => ["get", "update", "patch"]
      }
    ]

    :role
    |> B.build_resource()
    |> B.name("aws-load-balancer-controller-leader-election-role")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:service_account_aws_load_balancer_controller, battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.annotation("eks.amazonaws.com/role-arn", battery.config.service_role_arn)
  end

  resource(:service_aws_load_balancer_webhook, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "webhook-server", "port" => 443, "targetPort" => "webhook-server"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name})

    :service
    |> B.build_resource()
    |> B.name("aws-load-balancer-webhook-service")
    |> B.namespace(namespace)
    |> B.component_labels("webhook")
    |> B.label("prometheus.io/service-monitor", "false")
    |> B.spec(spec)
  end

  resource(:cert, _battery, state) do
    namespace = base_namespace(state)
    svc_name = "aws-load-balancer-webhook-service"

    spec =
      %{
        "dnsNames" => ["#{svc_name}.#{namespace}.svc", "#{svc_name}.#{namespace}.svc.cluster.local"],
        "issuerRef" => %{group: "cert-manager.io", kind: "ClusterIssuer", name: "battery-ca"},
        "secretName" => "aws-load-balancer-tls"
      }

    :certmanager_certificate
    |> B.build_resource()
    |> B.name("aws-load-balancer-controller-serving-cert")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:validating_webhook_config_aws_load_balancer, _battery, state) do
    namespace = base_namespace(state)

    :validating_webhook_config
    |> B.build_resource()
    |> B.name("aws-load-balancer-webhook")
    |> B.annotation("cert-manager.io/inject-ca-from", "#{namespace}/aws-load-balancer-controller-serving-cert")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "aws-load-balancer-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-elbv2-k8s-aws-v1beta1-ingressclassparams"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "vingressclassparams.elbv2.k8s.aws",
        "objectSelector" => %{
          "matchExpressions" => [
            %{"key" => "battery/app", "operator" => "NotIn", "values" => [@app_name]}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => ["elbv2.k8s.aws"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["ingressclassparams"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "aws-load-balancer-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-elbv2-k8s-aws-v1beta1-targetgroupbinding"
          }
        },
        "failurePolicy" => "Fail",
        "name" => "vtargetgroupbinding.elbv2.k8s.aws",
        "rules" => [
          %{
            "apiGroups" => ["elbv2.k8s.aws"],
            "apiVersions" => ["v1beta1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["targetgroupbindings"]
          }
        ],
        "sideEffects" => "None"
      },
      %{
        "admissionReviewVersions" => ["v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "aws-load-balancer-webhook-service",
            "namespace" => namespace,
            "path" => "/validate-networking-v1-ingress"
          }
        },
        "failurePolicy" => "Fail",
        "matchPolicy" => "Equivalent",
        "name" => "vingress.elbv2.k8s.aws",
        "rules" => [
          %{
            "apiGroups" => ["networking.k8s.io"],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["ingresses"]
          }
        ],
        "sideEffects" => "None"
      }
    ])
  end
end
