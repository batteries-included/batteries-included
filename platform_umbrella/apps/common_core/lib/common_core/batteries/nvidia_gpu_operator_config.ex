defmodule CommonCore.Batteries.NvidiaGPUOperatorConfig do
  @moduledoc """
  Configuration for the NVIDIA GPU Operator battery.

  The GPU Operator uses the operator framework within Kubernetes to automate the management
  of all NVIDIA software components needed to provision GPU workloads. These components
  include the NVIDIA drivers, Kubernetes device plugin for GPUs, the NVIDIA Container
  Toolkit, automatic node labelling using GPU Feature Discovery (GFD), DCGM-based
  monitoring, and others.

  ## Component Groups

  ### Core GPU Support
  - **Driver**: NVIDIA GPU drivers for enabling CUDA functionality
  - **Device Plugin**: Kubernetes device plugin for exposing GPUs to containers
  - **Container Toolkit**: NVIDIA container runtime for GPU access in containers
  - **GPU Feature Discovery (GFD)**: Automatic GPU node labeling

  ### Monitoring and Observability
  - **DCGM**: Data Center GPU Manager for GPU health monitoring
  - **DCGM Exporter**: Prometheus metrics exporter for GPU telemetry
  - **Node Status Exporter**: Additional node-level GPU status reporting

  ### Advanced GPU Features
  - **MIG Manager**: Multi-Instance GPU configuration management
  - **GDRCopy**: GPU Direct RDMA Copy support for high-performance computing

  ### Virtualization Support
  - **vGPU Manager**: NVIDIA vGPU support for virtualized environments
  - **vGPU Device Manager**: Device management for vGPU configurations
  - **Sandbox Device Plugin**: GPU support for KubeVirt and similar platforms

  ### Security and Isolation
  - **Confidential Computing Manager**: Support for confidential containers
  - **Kata Manager**: Integration with Kata Containers for secure workloads
  - **VFIO Manager**: VFIO-based GPU passthrough support

  ### Container Device Interface
  - **CDI**: Container Device Interface for standardized GPU access
  """
  use CommonCore, :embedded_schema

  @required_fields ~w()a

  batt_polymorphic_schema type: :nvidia_gpu_operator do
    # === CORE GPU SUPPORT ===
    # Primary NVIDIA GPU Operator controller
    defaultable_image_field :gpu_operator_image, image_id: :nvidia_gpu_operator
    field :log_level, :string, default: "debug"

    # GPU Driver - Installs and manages NVIDIA GPU drivers
    defaultable_field :driver_enabled, :boolean, default: false

    defaultable_image_field :driver_image, image_id: :nvidia_driver
    defaultable_image_field :k8s_driver_manager_image, image_id: :nvidia_k8s_driver_manager

    defaultable_field :driver_kernel_module_type, :string, default: "auto"
    defaultable_field :driver_use_precompiled, :boolean, default: false
    defaultable_field :driver_rdma_enabled, :boolean, default: false
    defaultable_field :driver_rdma_use_host_mofed, :boolean, default: false
    defaultable_field :driver_auto_upgrade, :boolean, default: true
    defaultable_field :driver_max_parallel_upgrades, :integer, default: 1
    defaultable_field :driver_max_unavailable, :string, default: "25%"

    # Device Plugin - Exposes GPUs as schedulable resources in Kubernetes
    defaultable_image_field :device_plugin_image, image_id: :nvidia_device_plugin
    defaultable_field :device_plugin_enabled, :boolean, default: true

    # Container Toolkit - Provides container runtime support for GPUs
    defaultable_field :toolkit_enabled, :boolean, default: false
    defaultable_image_field :container_toolkit_image, image_id: :nvidia_container_toolkit

    # GPU Feature Discovery - Automatic node labeling based on GPU capabilities
    defaultable_field :gfd_enabled, :boolean, default: false
    defaultable_field :gfd_sleep_interval, :string, default: "60s"

    # === MONITORING AND OBSERVABILITY ===
    # DCGM - Data Center GPU Manager for health monitoring
    defaultable_field :dcgm_enabled, :boolean, default: false
    defaultable_image_field :dcgm_image, image_id: :nvidia_dcgm

    # DCGM Exporter - Prometheus metrics for GPU telemetry
    defaultable_image_field :dcgm_exporter_image, image_id: :nvidia_dcgm_exporter
    defaultable_field :dcgm_exporter_scrape_interval, :string, default: "15s"

    # Node Status Exporter - Additional node-level GPU status
    defaultable_field :node_status_exporter_enabled, :boolean, default: false
    defaultable_image_field :gpu_operator_validator_image, image_id: :nvidia_gpu_operator_validator

    # === ADVANCED GPU FEATURES ===
    # MIG Manager - Multi-Instance GPU support
    defaultable_field :mig_manager_enabled, :boolean, default: false
    defaultable_image_field :k8s_mig_manager_image, image_id: :nvidia_k8s_mig_manager
    defaultable_field :mig_strategy, :string, default: "single"

    # GDRCopy - GPU Direct RDMA Copy for high-performance computing
    defaultable_field :gdrcopy_enabled, :boolean, default: false
    defaultable_image_field :gdrdrv_image, image_id: :nvidia_gdrdrv

    # === VIRTUALIZATION SUPPORT ===
    # vGPU Support - Virtual GPU functionality
    defaultable_field :vgpu_manager_enabled, :boolean, default: false
    defaultable_field :vgpu_device_manager_enabled, :boolean, default: false
    defaultable_image_field :vgpu_device_manager_image, image_id: :nvidia_vgpu_device_manager

    # Sandbox Workloads - Support for KubeVirt and similar platforms
    defaultable_field :sandbox_workloads_enabled, :boolean, default: false
    defaultable_field :sandbox_device_plugin_enabled, :boolean, default: false
    defaultable_image_field :kubevirt_gpu_device_plugin_image, image_id: :nvidia_kubevirt_gpu_device_plugin
    defaultable_field :sandbox_default_workload, :string, default: "container"

    # === SECURITY AND ISOLATION ===
    # Confidential Computing - Support for confidential containers
    defaultable_field :cc_manager_enabled, :boolean, default: false
    defaultable_image_field :k8s_cc_manager_image, image_id: :nvidia_k8s_cc_manager

    # Kata Containers - Secure container runtime integration
    defaultable_field :kata_manager_enabled, :boolean, default: false
    defaultable_image_field :k8s_kata_manager_image, image_id: :nvidia_k8s_kata_manager
    defaultable_image_field :kata_gpu_artifacts_image, image_id: :nvidia_kata_gpu_artifacts
    defaultable_image_field :kata_gpu_artifacts_snp_image, image_id: :nvidia_kata_gpu_artifacts_snp

    # VFIO Manager - VFIO-based GPU passthrough
    defaultable_field :vfio_manager_enabled, :boolean, default: false
    defaultable_image_field :cuda_image, image_id: :nvidia_cuda

    # === CONTAINER DEVICE INTERFACE ===
    # CDI - Container Device Interface for standardized device access
    defaultable_field :cdi_enabled, :boolean, default: false
    defaultable_field :cdi_default, :boolean, default: false

    # === CLUSTER MANAGEMENT ===
    # Pod Security Standards support
    defaultable_field :psa_enabled, :boolean, default: false
  end
end
