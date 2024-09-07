defmodule CommonCore.Resources.NvidiaDevicePlugin do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "nvidia-device-plugin"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  resource(:nvidia_device_plugin, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put("metadata", %{"labels" => %{"battery/managed" => "true"}})
      |> Map.put(
        "spec",
        %{
          "affinity" => %{
            "nodeAffinity" => %{
              "requiredDuringSchedulingIgnoredDuringExecution" => %{
                "nodeSelectorTerms" => [
                  %{
                    "matchExpressions" => [
                      %{"key" => "feature.node.kubernetes.io/pci-10de.present", "operator" => "In", "values" => ["true"]}
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
                    "matchExpressions" => [%{"key" => "nvidia.com/gpu.present", "operator" => "In", "values" => ["true"]}]
                  }
                ]
              }
            }
          },
          "containers" => [
            %{
              "command" => ["nvidia-device-plugin"],
              "env" => [
                %{"name" => "MPS_ROOT", "value" => "/run/nvidia/mps"},
                %{"name" => "NVIDIA_VISIBLE_DEVICES", "value" => "all"},
                %{"name" => "NVIDIA_DRIVER_CAPABILITIES", "value" => "compute,utility"}
              ],
              "image" => battery.config.image,
              "name" => "nvidia-device-plugin-ctr",
              "securityContext" => %{"allowPrivilegeEscalation" => false, "capabilities" => %{"drop" => ["ALL"]}},
              "volumeMounts" => [
                %{"mountPath" => "/var/lib/kubelet/device-plugins", "name" => "device-plugin"},
                %{"mountPath" => "/dev/shm", "name" => "mps-shm"},
                %{"mountPath" => "/mps", "name" => "mps-root"},
                %{"mountPath" => "/var/run/cdi", "name" => "cdi-root"}
              ]
            }
          ],
          "tolerations" => [
            %{"key" => "CriticalAddonsOnly", "operator" => "Exists"},
            %{"effect" => "NoSchedule", "key" => "nvidia.com/gpu", "operator" => "Exists"}
          ],
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

  resource(:mps_control, battery, state) do
    namespace = core_namespace(state)

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "annotations" => %{},
          "labels" => %{
            "battery/managed" => "true"
          }
        }
      )
      |> Map.put(
        "spec",
        %{
          "affinity" => %{
            "nodeAffinity" => %{
              "requiredDuringSchedulingIgnoredDuringExecution" => %{
                "nodeSelectorTerms" => [
                  %{
                    "matchExpressions" => [
                      %{"key" => "feature.node.kubernetes.io/pci-10de.present", "operator" => "In", "values" => ["true"]}
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
                    "matchExpressions" => [%{"key" => "nvidia.com/gpu.present", "operator" => "In", "values" => ["true"]}]
                  }
                ]
              }
            }
          },
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
          "tolerations" => [
            %{"key" => "CriticalAddonsOnly", "operator" => "Exists"},
            %{"effect" => "NoSchedule", "key" => "nvidia.com/gpu", "operator" => "Exists"}
          ],
          "volumes" => [
            %{"hostPath" => %{"path" => "/run/nvidia/mps", "type" => "DirectoryOrCreate"}, "name" => "mps-root"},
            %{"hostPath" => %{"path" => "/run/nvidia/mps/shm"}, "name" => "mps-shm"}
          ]
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.component_labels("mps-control-daemon")

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
end
