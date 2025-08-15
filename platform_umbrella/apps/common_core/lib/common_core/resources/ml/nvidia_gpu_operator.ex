defmodule CommonCore.Resources.NvidiaGPUOperator do
  @moduledoc false
  use CommonCore.IncludeResource,
    clusterpolicies_nvidia_com: "priv/manifests/nvidia_gpu_operator/clusterpolicies_nvidia_com.yaml",
    nvidiadrivers_nvidia_com: "priv/manifests/nvidia_gpu_operator/nvidiadrivers_nvidia_com.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "nvidia-gpu-operator"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Util.Images

  resource(:crd_clusterpolicies_nvidia_com) do
    YamlElixir.read_all_from_string!(get_resource(:clusterpolicies_nvidia_com))
  end

  resource(:crd_nvidiadrivers_nvidia_com) do
    YamlElixir.read_all_from_string!(get_resource(:nvidiadrivers_nvidia_com))
  end

  resource(:cluster_role_binding_gpu_operator, _battery, state) do
    namespace = ai_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("gpu-operator")
    |> B.role_ref(B.build_cluster_role_ref("gpu-operator"))
    |> B.subject(B.build_service_account("gpu-operator", namespace))
  end

  resource(:cluster_role_gpu_operator) do
    rules = [
      %{
        "apiGroups" => ["config.openshift.io"],
        "resources" => ["clusterversions", "proxies"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["image.openshift.io"],
        "resources" => ["imagestreams"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["security.openshift.io"],
        "resources" => ["securitycontextconstraints"],
        "verbs" => ["create", "get", "list", "watch", "update", "patch", "delete", "use"]
      },
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["clusterroles", "clusterrolebindings"],
        "verbs" => ["create", "get", "list", "watch", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["nodes"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["namespaces"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["events"],
        "verbs" => ["create", "get", "list", "watch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["pods/eviction"], "verbs" => ["create"]},
      %{
        "apiGroups" => ["apps"],
        "resources" => ["daemonsets"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["nvidia.com"],
        "resources" => [
          "clusterpolicies",
          "clusterpolicies/finalizers",
          "clusterpolicies/status",
          "nvidiadrivers",
          "nvidiadrivers/finalizers",
          "nvidiadrivers/status"
        ],
        "verbs" => [
          "create",
          "get",
          "list",
          "watch",
          "update",
          "patch",
          "delete",
          "deletecollection"
        ]
      },
      %{
        "apiGroups" => ["scheduling.k8s.io"],
        "resources" => ["priorityclasses"],
        "verbs" => ["get", "list", "watch", "create"]
      },
      %{
        "apiGroups" => ["node.k8s.io"],
        "resources" => ["runtimeclasses"],
        "verbs" => ["get", "list", "create", "update", "watch", "delete"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch", "update", "patch", "create"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("gpu-operator")
    |> B.component_labels("gpu-operator")
    |> B.rules(rules)
  end

  resource(:deployment_gpu_operator, battery, state) do
    namespace = ai_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{
        "labels" => %{
          "battery/managed" => "true",
          "nvidia.com/gpu-driver-upgrade-drain.skip" => "true"
        }
      })
      |> Map.put("spec", %{
        "containers" => [
          %{
            "args" => ["--leader-elect", "--zap-time-encoding=epoch", "--zap-log-level=#{battery.config.log_level}"],
            "command" => ["gpu-operator"],
            "env" => [
              %{"name" => "WATCH_NAMESPACE", "value" => ""},
              %{
                "name" => "OPERATOR_NAMESPACE",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
              },
              %{
                "name" => "DRIVER_MANAGER_IMAGE",
                "value" => battery.config.k8s_driver_manager_image
              }
            ],
            "image" => battery.config.gpu_operator_image,
            "imagePullPolicy" => "IfNotPresent",
            "livenessProbe" => %{
              "httpGet" => %{"path" => "/healthz", "port" => 8081},
              "initialDelaySeconds" => 15,
              "periodSeconds" => 20
            },
            "name" => "gpu-operator",
            "ports" => [%{"containerPort" => 8080, "name" => "metrics"}],
            "readinessProbe" => %{
              "httpGet" => %{"path" => "/readyz", "port" => 8081},
              "initialDelaySeconds" => 5,
              "periodSeconds" => 10
            },
            "resources" => %{
              "limits" => %{"memory" => "350Mi"},
              "requests" => %{"cpu" => "200m", "memory" => "100Mi"}
            },
            "volumeMounts" => [
              %{
                "mountPath" => "/host-etc/os-release",
                "name" => "host-os-release",
                "readOnly" => true
              }
            ]
          }
        ],
        "priorityClassName" => "system-node-critical",
        "serviceAccountName" => "gpu-operator",
        "tolerations" => [
          %{
            "effect" => "NoSchedule",
            "key" => "node-role.kubernetes.io/master",
            "operator" => "Equal",
            "value" => ""
          },
          %{
            "effect" => "NoSchedule",
            "key" => "node-role.kubernetes.io/control-plane",
            "operator" => "Equal",
            "value" => ""
          }
        ],
        "volumes" => [
          %{"hostPath" => %{"path" => "/etc/os-release"}, "name" => "host-os-release"}
        ]
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.component_labels("gpu-operator")
      |> B.label("nvidia.com/gpu-driver-upgrade-drain.skip", "true")

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put("selector", %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "battery/component" => "gpu-operator"
        }
      })
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("gpu-operator")
    |> B.namespace(namespace)
    |> B.label("nvidia.com/gpu-driver-upgrade-drain.skip", "true")
    |> B.spec(spec)
  end

  # Helper functions for building GPU operator spec components

  defp cc_manager_config(battery, _state) do
    %{
      "defaultMode" => "off",
      "enabled" => battery.config.cc_manager_enabled,
      "env" => [],
      "image" => Images.image(battery.config.k8s_cc_manager_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.k8s_cc_manager_image),
      "version" => Images.version(battery.config.k8s_cc_manager_image)
    }
  end

  defp cdi_config(battery, _state) do
    %{
      "default" => battery.config.cdi_default,
      "enabled" => battery.config.cdi_enabled
    }
  end

  defp daemonsets_config(_battery, _state) do
    %{
      "labels" => %{
        "battery/managed" => "true",
        "app.kubernetes.io/managed-by" => "batteries-included",
        "battery/managed.indirect" => "true"
      },
      "priorityClassName" => "system-node-critical",
      "rollingUpdate" => %{"maxUnavailable" => "1"},
      "tolerations" => [
        %{"effect" => "NoSchedule", "key" => "nvidia.com/gpu", "operator" => "Exists"}
      ],
      "updateStrategy" => "RollingUpdate"
    }
  end

  defp dcgm_config(battery, _state) do
    %{
      "enabled" => battery.config.dcgm_enabled,
      "image" => Images.image(battery.config.dcgm_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.dcgm_image),
      "version" => Images.version(battery.config.dcgm_image)
    }
  end

  defp dcgm_exporter_config(battery, state) do
    enabled =
      battery.config.dcgm_enabled &&
        CommonCore.StateSummary.Batteries.victoria_metrics_installed?(state)

    %{
      # This should be enabled if dgcm is enabled and vmagent battery is running.
      "enabled" => enabled,
      "env" => [
        %{"name" => "DCGM_EXPORTER_LISTEN", "value" => ":9400"},
        %{"name" => "DCGM_EXPORTER_KUBERNETES", "value" => "true"},
        %{
          "name" => "DCGM_EXPORTER_COLLECTORS",
          "value" => "/etc/dcgm-exporter/dcp-metrics-included.csv"
        }
      ],
      "image" => Images.image(battery.config.dcgm_exporter_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.dcgm_exporter_image),
      "service" => %{"internalTrafficPolicy" => "Cluster"},
      "serviceMonitor" => %{
        "additionalLabels" => %{},

        # This is false since we we use vmscrape variants. The CRD's aren't the same.
        "enabled" => false,
        "honorLabels" => false,
        "interval" => battery.config.dcgm_exporter_scrape_interval,
        "relabelings" => []
      },
      "version" => Images.version(battery.config.dcgm_exporter_image)
    }
  end

  defp device_plugin_config(battery, _state) do
    %{
      "enabled" => battery.config.device_plugin_enabled,
      "env" => [
        %{"name" => "PASS_DEVICE_SPECS", "value" => "true"},
        %{"name" => "FAIL_ON_INIT_ERROR", "value" => "true"},
        %{"name" => "DEVICE_LIST_STRATEGY", "value" => "envvar"},
        %{"name" => "DEVICE_ID_STRATEGY", "value" => "uuid"},
        %{"name" => "NVIDIA_VISIBLE_DEVICES", "value" => "all"},
        %{"name" => "NVIDIA_DRIVER_CAPABILITIES", "value" => "all"}
      ],
      "image" => Images.image(battery.config.device_plugin_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.device_plugin_image),
      "version" => Images.version(battery.config.device_plugin_image)
    }
  end

  defp driver_config(battery, _state) do
    %{
      "certConfig" => %{"name" => ""},
      "enabled" => battery.config.driver_enabled,
      "image" => Images.image(battery.config.driver_image),
      "imagePullPolicy" => "IfNotPresent",
      "kernelModuleConfig" => %{"name" => ""},
      "kernelModuleType" => battery.config.driver_kernel_module_type,
      "licensingConfig" => %{"configMapName" => "", "nlsEnabled" => true},
      "manager" => %{
        "env" => [
          %{"name" => "ENABLE_GPU_POD_EVICTION", "value" => "true"},
          %{"name" => "ENABLE_AUTO_DRAIN", "value" => "false"},
          %{"name" => "DRAIN_USE_FORCE", "value" => "false"},
          %{"name" => "DRAIN_POD_SELECTOR_LABEL", "value" => ""},
          %{"name" => "DRAIN_TIMEOUT_SECONDS", "value" => "0s"},
          %{"name" => "DRAIN_DELETE_EMPTYDIR_DATA", "value" => "false"}
        ],
        "image" => Images.image(battery.config.k8s_driver_manager_image),
        "imagePullPolicy" => "IfNotPresent",
        "repository" => Images.repository(battery.config.k8s_driver_manager_image),
        "version" => Images.version(battery.config.k8s_driver_manager_image)
      },
      "rdma" => %{
        "enabled" => battery.config.driver_rdma_enabled,
        "useHostMofed" => battery.config.driver_rdma_use_host_mofed
      },
      "repoConfig" => %{"configMapName" => ""},
      "repository" => Images.repository(battery.config.driver_image),
      "startupProbe" => %{
        "failureThreshold" => 120,
        "initialDelaySeconds" => 60,
        "periodSeconds" => 10,
        "timeoutSeconds" => 60
      },
      "upgradePolicy" => %{
        "autoUpgrade" => battery.config.driver_auto_upgrade,
        "drain" => %{
          "deleteEmptyDir" => false,
          "enable" => false,
          "force" => false,
          "timeoutSeconds" => 300
        },
        "maxParallelUpgrades" => battery.config.driver_max_parallel_upgrades,
        "maxUnavailable" => battery.config.driver_max_unavailable,
        "podDeletion" => %{"deleteEmptyDir" => false, "force" => false, "timeoutSeconds" => 300},
        "waitForCompletion" => %{"timeoutSeconds" => 0}
      },
      "useNvidiaDriverCRD" => false,
      "usePrecompiled" => battery.config.driver_use_precompiled,
      "version" => Images.version(battery.config.driver_image),
      "virtualTopology" => %{"config" => ""}
    }
  end

  defp gdrcopy_config(battery, _state) do
    %{
      "enabled" => battery.config.gdrcopy_enabled,
      "image" => Images.image(battery.config.gdrdrv_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.gdrdrv_image),
      "version" => Images.version(battery.config.gdrdrv_image)
    }
  end

  defp gfd_config(battery, _state) do
    %{
      "enabled" => battery.config.gfd_enabled,
      "env" => [
        %{"name" => "GFD_SLEEP_INTERVAL", "value" => battery.config.gfd_sleep_interval},
        %{"name" => "GFD_FAIL_ON_INIT_ERROR", "value" => "true"}
      ],
      "image" => Images.image(battery.config.device_plugin_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.device_plugin_image),
      "version" => Images.version(battery.config.device_plugin_image)
    }
  end

  defp host_paths_config(_battery, _state) do
    %{"driverInstallDir" => "/run/nvidia/driver", "rootFS" => "/"}
  end

  defp kata_manager_config(battery, _state) do
    %{
      "config" => %{
        "artifactsDir" => "/opt/nvidia-gpu-operator/artifacts/runtimeclasses",
        "runtimeClasses" => [
          %{
            "artifacts" => %{
              "pullSecret" => "",
              "url" => battery.config.kata_gpu_artifacts_image
            },
            "name" => "kata-nvidia-gpu",
            "nodeSelector" => %{}
          },
          %{
            "artifacts" => %{
              "pullSecret" => "",
              "url" => battery.config.kata_gpu_artifacts_snp_image
            },
            "name" => "kata-nvidia-gpu-snp",
            "nodeSelector" => %{"nvidia.com/cc.capable" => "true"}
          }
        ]
      },
      "enabled" => battery.config.kata_manager_enabled,
      "image" => Images.image(battery.config.k8s_kata_manager_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.k8s_kata_manager_image),
      "version" => Images.version(battery.config.k8s_kata_manager_image)
    }
  end

  defp mig_config(battery, _state) do
    %{"strategy" => battery.config.mig_strategy}
  end

  defp mig_manager_config(battery, _state) do
    %{
      "config" => %{"default" => "all-disabled", "name" => nil},
      "enabled" => battery.config.mig_manager_enabled,
      "env" => [%{"name" => "WITH_REBOOT", "value" => "false"}],
      "gpuClientsConfig" => %{"name" => ""},
      "image" => Images.image(battery.config.k8s_mig_manager_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.k8s_mig_manager_image),
      "version" => Images.version(battery.config.k8s_mig_manager_image)
    }
  end

  defp node_status_exporter_config(battery, _state) do
    %{
      "enabled" => battery.config.node_status_exporter_enabled,
      "image" => Images.image(battery.config.gpu_operator_validator_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.gpu_operator_validator_image),
      "version" => Images.version(battery.config.gpu_operator_validator_image)
    }
  end

  defp operator_config(battery, _state) do
    %{
      "initContainer" => %{
        "image" => Images.image(battery.config.cuda_image),
        "imagePullPolicy" => "IfNotPresent",
        "repository" => Images.repository(battery.config.cuda_image),
        "version" => Images.version(battery.config.cuda_image)
      },
      "runtimeClass" => "nvidia"
    }
  end

  defp psa_config(battery, _state) do
    %{"enabled" => battery.config.psa_enabled}
  end

  defp sandbox_device_plugin_config(battery, _state) do
    %{
      "enabled" => battery.config.sandbox_device_plugin_enabled,
      "image" => Images.image(battery.config.kubevirt_gpu_device_plugin_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.kubevirt_gpu_device_plugin_image),
      "version" => Images.version(battery.config.kubevirt_gpu_device_plugin_image)
    }
  end

  defp sandbox_workloads_config(battery, _state) do
    %{
      "defaultWorkload" => battery.config.sandbox_default_workload,
      "enabled" => battery.config.sandbox_workloads_enabled
    }
  end

  defp toolkit_config(battery, _state) do
    %{
      "enabled" => battery.config.toolkit_enabled,
      "image" => Images.image(battery.config.container_toolkit_image),
      "imagePullPolicy" => "IfNotPresent",
      "installDir" => "/usr/local/nvidia",
      "repository" => Images.repository(battery.config.container_toolkit_image),
      "version" => Images.version(battery.config.container_toolkit_image)
    }
  end

  defp validator_config(battery, _state) do
    %{
      "image" => Images.image(battery.config.gpu_operator_validator_image),
      "imagePullPolicy" => "IfNotPresent",
      "plugin" => %{"env" => [%{"name" => "WITH_WORKLOAD", "value" => "false"}]},
      "repository" => Images.repository(battery.config.gpu_operator_validator_image),
      "version" => Images.version(battery.config.gpu_operator_validator_image)
    }
  end

  defp vfio_manager_config(battery, _state) do
    %{
      "driverManager" => %{
        "env" => [
          %{"name" => "ENABLE_GPU_POD_EVICTION", "value" => "false"},
          %{"name" => "ENABLE_AUTO_DRAIN", "value" => "false"}
        ],
        "image" => Images.image(battery.config.k8s_driver_manager_image),
        "imagePullPolicy" => "IfNotPresent",
        "repository" => Images.repository(battery.config.k8s_driver_manager_image),
        "version" => Images.version(battery.config.k8s_driver_manager_image)
      },
      "enabled" => battery.config.vfio_manager_enabled,
      "image" => Images.image(battery.config.cuda_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.cuda_image),
      "version" => Images.version(battery.config.cuda_image)
    }
  end

  defp vgpu_device_manager_config(battery, _state) do
    %{
      "config" => %{"default" => "default", "name" => ""},
      "enabled" => battery.config.vgpu_device_manager_enabled,
      "image" => Images.image(battery.config.vgpu_device_manager_image),
      "imagePullPolicy" => "IfNotPresent",
      "repository" => Images.repository(battery.config.vgpu_device_manager_image),
      "version" => Images.version(battery.config.vgpu_device_manager_image)
    }
  end

  defp vgpu_manager_config(battery, _state) do
    %{
      "driverManager" => %{
        "env" => [
          %{"name" => "ENABLE_GPU_POD_EVICTION", "value" => "false"},
          %{"name" => "ENABLE_AUTO_DRAIN", "value" => "false"}
        ],
        "image" => Images.image(battery.config.k8s_driver_manager_image),
        "imagePullPolicy" => "IfNotPresent",
        "repository" => Images.repository(battery.config.k8s_driver_manager_image),
        "version" => Images.version(battery.config.k8s_driver_manager_image)
      },
      "enabled" => battery.config.vgpu_manager_enabled,
      "image" => "vgpu-manager",
      "imagePullPolicy" => "IfNotPresent"
    }
  end

  resource(:nvidia_cluster_policy_main, battery, state) do
    _namespace = ai_namespace(state)

    spec =
      %{}
      |> Map.put("ccManager", cc_manager_config(battery, state))
      |> Map.put("cdi", cdi_config(battery, state))
      |> Map.put("daemonsets", daemonsets_config(battery, state))
      |> Map.put("dcgm", dcgm_config(battery, state))
      |> Map.put("dcgmExporter", dcgm_exporter_config(battery, state))
      |> Map.put("devicePlugin", device_plugin_config(battery, state))
      |> Map.put("driver", driver_config(battery, state))
      |> Map.put("gdrcopy", gdrcopy_config(battery, state))
      |> Map.put("gfd", gfd_config(battery, state))
      |> Map.put("hostPaths", host_paths_config(battery, state))
      |> Map.put("kataManager", kata_manager_config(battery, state))
      |> Map.put("mig", mig_config(battery, state))
      |> Map.put("migManager", mig_manager_config(battery, state))
      |> Map.put("nodeStatusExporter", node_status_exporter_config(battery, state))
      |> Map.put("operator", operator_config(battery, state))
      |> Map.put("psa", psa_config(battery, state))
      |> Map.put("sandboxDevicePlugin", sandbox_device_plugin_config(battery, state))
      |> Map.put("sandboxWorkloads", sandbox_workloads_config(battery, state))
      |> Map.put("toolkit", toolkit_config(battery, state))
      |> Map.put("validator", validator_config(battery, state))
      |> Map.put("vfioManager", vfio_manager_config(battery, state))
      |> Map.put("vgpuDeviceManager", vgpu_device_manager_config(battery, state))
      |> Map.put("vgpuManager", vgpu_manager_config(battery, state))

    :nvidia_cluster_policy
    |> B.build_resource()
    |> B.name("cluster-policy")
    |> B.component_labels("gpu-operator")
    |> B.spec(spec)
  end

  resource(:role_binding_gpu_operator, _battery, state) do
    namespace = ai_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("gpu-operator")
    |> B.component_labels("gpu-operator")
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref("gpu-operator"))
    |> B.subject(B.build_service_account("gpu-operator", namespace))
  end

  resource(:role_gpu_operator, _battery, state) do
    namespace = ai_namespace(state)

    rules = [
      %{
        "apiGroups" => ["rbac.authorization.k8s.io"],
        "resources" => ["roles", "rolebindings"],
        "verbs" => ["create", "get", "list", "watch", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["controllerrevisions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["daemonsets"],
        "verbs" => ["create", "get", "list", "watch", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "configmaps",
          "endpoints",
          "pods",
          "pods/eviction",
          "secrets",
          "services",
          "services/finalizers",
          "serviceaccounts"
        ],
        "verbs" => ["create", "get", "list", "watch", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resources" => ["leases"],
        "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
      },
      %{
        "apiGroups" => ["monitoring.coreos.com"],
        "resources" => ["servicemonitors", "prometheusrules"],
        "verbs" => ["get", "list", "create", "watch", "update", "delete"]
      }
    ]

    :role
    |> B.build_resource()
    |> B.name("gpu-operator")
    |> B.component_labels("gpu-operator")
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  resource(:service_account_gpu_operator, _battery, state) do
    namespace = ai_namespace(state)

    :service_account
    |> B.build_resource()
    |> B.name("gpu-operator")
    |> B.namespace(namespace)
    |> B.component_labels("gpu-operator")
  end
end
