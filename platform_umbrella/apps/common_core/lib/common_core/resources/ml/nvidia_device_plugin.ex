defmodule CommonCore.Resources.NvidiaDevicePlugin do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "nvidia-device-plugin"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.StateSummary.Core

  defp nvidia_gpu_affinity do
    %{
      "nodeAffinity" => %{
        "requiredDuringSchedulingIgnoredDuringExecution" => %{
          "nodeSelectorTerms" => [
            %{
              "matchExpressions" => [
                %{
                  "key" => "feature.node.kubernetes.io/pci-10de.present",
                  "operator" => "In",
                  "values" => ["true"]
                }
              ]
            },
            %{
              "matchExpressions" => [
                %{
                  "key" => "feature.node.kubernetes.io/cpu-model.vendor_id",
                  "operator" => "In",
                  "values" => ["NVIDIA"]
                }
              ]
            },
            %{
              "matchExpressions" => [
                %{"key" => "nvidia.com/gpu.present", "operator" => "In", "values" => ["true"]}
              ]
            }
          ]
        }
      }
    }
  end

  defp maybe_add_runtime(template, false = _is_kind_provider) do
    template
  end

  defp maybe_add_runtime(template, true = _is_kind_provider) do
    update_in(template, ["spec"], fn spec -> Map.put(spec, "runtimeClassName", "nvidia") end)
  end

  defp nvidia_tolerations do
    [
      %{"key" => "CriticalAddonsOnly", "operator" => "Exists"},
      %{"effect" => "NoSchedule", "key" => "nvidia.com/gpu", "operator" => "Exists"}
    ]
  end

  resource(:nvidia_device_plugin, battery, state) do
    namespace = ai_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{"labels" => %{"battery/managed" => "true"}})
      |> Map.put(
        "spec",
        %{
          "affinity" => nvidia_gpu_affinity(),
          "containers" => [
            %{
              "command" => ["nvidia-device-plugin"],
              "env" => nvdp_env(Core.kind_cluster?(state)),
              "image" => battery.config.image,
              "name" => "nvidia-device-plugin-ctr",
              "securityContext" => nvdp_security_context(Core.kind_cluster?(state)),
              "volumeMounts" => [
                %{"mountPath" => "/var/lib/kubelet/device-plugins", "name" => "device-plugin"},
                %{"mountPath" => "/dev/shm", "name" => "mps-shm"},
                %{"mountPath" => "/mps", "name" => "mps-root"},
                %{"mountPath" => "/var/run/cdi", "name" => "cdi-root"}
              ]
            }
          ],
          "tolerations" => nvidia_tolerations(),
          "volumes" => [
            %{"hostPath" => %{"path" => "/var/lib/kubelet/device-plugins"}, "name" => "device-plugin"},
            %{"hostPath" => %{"path" => "/run/nvidia/mps", "type" => "DirectoryOrCreate"}, "name" => "mps-root"},
            %{"hostPath" => %{"path" => "/run/nvidia/mps/shm"}, "name" => "mps-shm"},
            %{"hostPath" => %{"path" => "/var/run/cdi", "type" => "DirectoryOrCreate"}, "name" => "cdi-root"}
          ]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.component_labels("nvidia-device-plugin")
      |> maybe_add_runtime(Core.kind_cluster?(state))

    spec =
      %{}
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "nvidia-device-plugin"}}
      )
      |> Map.put("updateStrategy", %{"type" => "RollingUpdate"})
      |> B.template(template)

    :daemon_set
    |> B.build_resource()
    |> B.name("nvdp-nvidia-device-plugin")
    |> B.component_labels("nvidia-device-plugin")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  # This is the security context for the NVIDIA device plugin container
  defp nvdp_security_context(false = _is_kind_provider),
    do: %{"allowPrivilegeEscalation" => false, "capabilities" => %{"drop" => ["ALL"]}}

  defp nvdp_security_context(true = _is_kind_provider), do: %{"capabilities" => %{"add" => ["SYS_ADMIN"]}}

  defp nvdp_env(false = _is_kind_provider) do
    [
      %{"name" => "MPS_ROOT", "value" => "/run/nvidia/mps"},
      %{"name" => "NVIDIA_VISIBLE_DEVICES", "value" => "all"},
      %{"name" => "NVIDIA_DRIVER_CAPABILITIES", "value" => "compute,utility"}
    ]
  end

  defp nvdp_env(true = _is_kind_provider) do
    [
      %{"name" => "MPS_ROOT", "value" => "/run/nvidia/mps"},
      %{"name" => "NVIDIA_VISIBLE_DEVICES", "value" => "all"},
      %{"name" => "DEVICE_LIST_STRATEGY", "value" => "volume-mounts"},
      %{"name" => "NVIDIA_DRIVER_CAPABILITIES", "value" => "compute,utility"}
    ]
  end

  resource(:mps_control, battery, state) do
    namespace = ai_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{"labels" => %{"battery/managed" => "true"}})
      |> Map.put(
        "spec",
        %{
          "affinity" => nvidia_gpu_affinity(),
          "containers" => [
            %{
              "command" => ["mps-control-daemon"],
              "env" => [
                %{
                  "name" => "NODE_NAME",
                  "valueFrom" => %{"fieldRef" => %{"apiVersion" => "v1", "fieldPath" => "spec.nodeName"}}
                },
                %{"name" => "NVIDIA_VISIBLE_DEVICES", "value" => "all"},
                %{"name" => "NVIDIA_DRIVER_CAPABILITIES", "value" => "compute,utility"}
              ],
              "image" => battery.config.image,
              "name" => "mps-control-daemon-ctr",
              "securityContext" => %{"privileged" => true},
              "volumeMounts" => [
                %{"mountPath" => "/dev/shm", "name" => "mps-shm"},
                %{"mountPath" => "/mps", "name" => "mps-root"}
              ]
            }
          ],
          "initContainers" => [
            %{
              "command" => ["mps-control-daemon", "mount-shm"],
              "image" => battery.config.image,
              "name" => "mps-control-daemon-mounts",
              "securityContext" => %{"privileged" => true},
              "volumeMounts" => [%{"mountPath" => "/mps", "mountPropagation" => "Bidirectional", "name" => "mps-root"}]
            }
          ],
          "nodeSelector" => %{"nvidia.com/mps.capable" => "true"},
          "priorityClassName" => "system-node-critical",
          "securityContext" => %{},
          "tolerations" => nvidia_tolerations(),
          "volumes" => [
            %{"hostPath" => %{"path" => "/run/nvidia/mps", "type" => "DirectoryOrCreate"}, "name" => "mps-root"},
            %{"hostPath" => %{"path" => "/run/nvidia/mps/shm"}, "name" => "mps-shm"}
          ]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.component_labels("mps-control-daemon")
      |> maybe_add_runtime(Core.kind_cluster?(state))

    spec =
      %{}
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => "mps-control-daemon"}}
      )
      |> Map.put("updateStrategy", %{"type" => "RollingUpdate"})
      |> B.template(template)

    :daemon_set
    |> B.build_resource()
    |> B.name("nvdp-mps-control-daemon")
    |> B.component_labels("mps-control-daemon")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:gpu_feature, battery, state) do
    namespace = ai_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{"labels" => %{"battery/managed" => "true"}})
      |> Map.put("spec", %{
        "affinity" => nvidia_gpu_affinity(),
        "containers" => [
          %{
            "command" => ["gpu-feature-discovery"],
            "env" => [
              %{
                "name" => "NODE_NAME",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
              },
              %{
                "name" => "NAMESPACE",
                "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
              },
              %{"name" => "GFD_USE_NODE_FEATURE_API", "value" => "false"},
              %{"name" => "DEVICE_DISCOVERY_STRATEGY", "value" => "nvml"}
            ],
            "image" => battery.config.image,
            "imagePullPolicy" => "IfNotPresent",
            "name" => "gpu-feature-discovery-ctr",
            "securityContext" => %{"privileged" => true},
            "volumeMounts" => [
              %{
                "mountPath" => "/etc/kubernetes/node-feature-discovery/features.d",
                "name" => "output-dir"
              },
              %{"mountPath" => "/sys", "name" => "host-sys"},
              %{"mountPath" => "/config", "name" => "config"}
            ]
          }
        ],
        "initContainers" => nil,
        "priorityClassName" => "system-node-critical",
        "runtimeClassName" => "nvidia",
        "securityContext" => %{},
        "tolerations" => nvidia_tolerations(),
        "volumes" => [
          %{
            "hostPath" => %{"path" => "/etc/kubernetes/node-feature-discovery/features.d"},
            "name" => "output-dir"
          },
          %{"hostPath" => %{"path" => "/sys"}, "name" => "host-sys"},
          %{"hostPath" => %{"path" => "/", "type" => "Directory"}, "name" => "driver-root"},
          %{"emptyDir" => %{}, "name" => "config"}
        ]
      })
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.component_labels("gpu-feature-discovery")
      |> maybe_add_runtime(Core.kind_cluster?(state))

    spec =
      %{}
      |> Map.put("selector", %{
        "matchLabels" => %{
          "battery/app" => @app_name,
          "battery/component" => "gpu-feature-discovery"
        }
      })
      |> Map.put("updateStrategy", %{"type" => "RollingUpdate"})
      |> B.template(template)

    :daemon_set
    |> B.build_resource()
    |> B.name("nvdp-gpu-feature-discovery")
    |> B.namespace(namespace)
    |> B.component_labels("gpu-feature-discovery")
    |> B.spec(spec)
  end
end
