defmodule ControlServerWeb.Batteries.NvidiaGpuOperatorForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        {@battery.description}
      </.panel>

      <.panel title="Core GPU Support">
        <.fieldset>
          <.field variant="beside">
            <:label>Enable GPU Driver</:label>
            <:note>Installs and manages NVIDIA GPU drivers for CUDA functionality</:note>
            <.input type="switch" field={@form[:driver_enabled_override]} />
          </.field>

          <.field variant="beside">
            <:label>Enable Device Plugin</:label>
            <:note>Kubernetes device plugin for exposing GPUs to containers</:note>
            <.input type="switch" field={@form[:device_plugin_enabled_override]} />
          </.field>

          <.field variant="beside">
            <:label>Enable Container Toolkit</:label>
            <:note>NVIDIA container runtime for GPU access in containers</:note>
            <.input type="switch" field={@form[:toolkit_enabled_override]} />
          </.field>

          <.field variant="beside">
            <:label>Enable GPU Feature Discovery</:label>
            <:note>Automatic GPU node labeling based on capabilities</:note>
            <.input type="switch" field={@form[:gfd_enabled_override]} />
          </.field>

          <%= if @form[:driver_enabled].value do %>
            <.field>
              <:label>Driver Kernel Module Type</:label>
              <:note>Method for loading GPU drivers (auto, native, or precompiled)</:note>
              <.input
                type="select"
                field={@form[:driver_kernel_module_type_override]}
                options={[
                  {"Auto", "auto"},
                  {"Native", "native"},
                  {"Precompiled", "precompiled"}
                ]}
              />
            </.field>

            <.field variant="beside">
              <:label>Use Precompiled Drivers</:label>
              <:note>Use precompiled drivers instead of building from source</:note>
              <.input type="switch" field={@form[:driver_use_precompiled_override]} />
            </.field>

            <.field variant="beside">
              <:label>Enable Auto Upgrade</:label>
              <:note>Automatically upgrade drivers when new versions are available</:note>
              <.input type="switch" field={@form[:driver_auto_upgrade_override]} />
            </.field>

            <.field>
              <:label>Max Parallel Upgrades</:label>
              <:note>Maximum number of nodes to upgrade simultaneously</:note>
              <.input type="number" field={@form[:driver_max_parallel_upgrades_override]} min="1" />
            </.field>

            <.field>
              <:label>Max Unavailable During Upgrade</:label>
              <:note>Maximum percentage or number of nodes unavailable during upgrade</:note>
              <.input field={@form[:driver_max_unavailable_override]} placeholder="25%" />
            </.field>
          <% end %>

          <%= if @form[:gfd_enabled].value do %>
            <.field>
              <:label>GFD Sleep Interval</:label>
              <:note>How often GPU Feature Discovery scans for changes</:note>
              <.input field={@form[:gfd_sleep_interval_override]} placeholder="60s" />
            </.field>
          <% end %>
        </.fieldset>
      </.panel>

      <.panel title="Monitoring & Observability">
        <.fieldset>
          <.field variant="beside">
            <:label>Enable DCGM</:label>
            <:note>Data Center GPU Manager for health monitoring</:note>
            <.input type="switch" field={@form[:dcgm_enabled_override]} />
          </.field>

          <%= if @form[:dcgm_enabled].value do %>
            <.field>
              <:label>DCGM Exporter Listen Port</:label>
              <:note>Port for Prometheus metrics export</:note>
              <.input
                type="number"
                field={@form[:dcgm_exporter_listen_port_override]}
                min="1"
                max="65535"
              />
            </.field>

            <.field>
              <:label>DCGM Exporter Scrape Interval</:label>
              <:note>How often metrics are collected</:note>
              <.input field={@form[:dcgm_exporter_scrape_interval_override]} placeholder="15s" />
            </.field>
          <% end %>

          <.field variant="beside">
            <:label>Enable Node Status Exporter</:label>
            <:note>Additional node-level GPU status reporting</:note>
            <.input type="switch" field={@form[:node_status_exporter_enabled_override]} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Advanced GPU Features">
        <.fieldset>
          <.field variant="beside">
            <:label>Enable MIG Manager</:label>
            <:note>Multi-Instance GPU configuration management</:note>
            <.input type="switch" field={@form[:mig_manager_enabled_override]} />
          </.field>

          <%= if @form[:mig_manager_enabled].value do %>
            <.field>
              <:label>MIG Strategy</:label>
              <:note>Strategy for MIG partitioning</:note>
              <.input
                type="select"
                field={@form[:mig_strategy_override]}
                options={[
                  {"Single", "single"},
                  {"Mixed", "mixed"}
                ]}
              />
            </.field>
          <% end %>

          <.field variant="beside">
            <:label>Enable GDRCopy</:label>
            <:note>GPU Direct RDMA Copy for high-performance computing</:note>
            <.input type="switch" field={@form[:gdrcopy_enabled_override]} />
          </.field>

          <.field variant="beside">
            <:label>Enable RDMA</:label>
            <:note>Remote Direct Memory Access support</:note>
            <.input type="switch" field={@form[:driver_rdma_enabled_override]} />
          </.field>

          <%= if @form[:driver_rdma_enabled].value do %>
            <.field variant="beside">
              <:label>Use Host MOFED</:label>
              <:note>Use host MOFED drivers instead of container MOFED</:note>
              <.input type="switch" field={@form[:driver_rdma_use_host_mofed_override]} />
            </.field>
          <% end %>
        </.fieldset>
      </.panel>

      <.panel title="Images">
        <.fieldset>
          <.image>
            {@form[:gpu_operator_image].value}<br />
            {@form[:driver_image].value}<br />
            {@form[:device_plugin_image].value}<br />
            {@form[:container_toolkit_image].value}
          </.image>

          <.image_version
            field={@form[:gpu_operator_image_tag_override]}
            image_id={:nvidia_gpu_operator}
            label="GPU Operator Version"
          />

          <.image_version
            field={@form[:driver_image_tag_override]}
            image_id={:nvidia_driver}
            label="Driver Version"
          />

          <.image_version
            field={@form[:device_plugin_image_tag_override]}
            image_id={:nvidia_device_plugin}
            label="Device Plugin Version"
          />

          <.image_version
            field={@form[:container_toolkit_image_tag_override]}
            image_id={:nvidia_container_toolkit}
            label="Container Toolkit Version"
          />

          <%= if @form[:dcgm_enabled].value do %>
            <.image_version
              field={@form[:dcgm_image_tag_override]}
              image_id={:nvidia_dcgm}
              label="DCGM Version"
            />

            <.image_version
              field={@form[:dcgm_exporter_image_tag_override]}
              image_id={:nvidia_dcgm_exporter}
              label="DCGM Exporter Version"
            />
          <% end %>

          <%= if @form[:mig_manager_enabled].value do %>
            <.image_version
              field={@form[:k8s_mig_manager_image_tag_override]}
              image_id={:nvidia_k8s_mig_manager}
              label="MIG Manager Version"
            />
          <% end %>

          <%= if @form[:gdrcopy_enabled].value do %>
            <.image_version
              field={@form[:gdrdrv_image_tag_override]}
              image_id={:nvidia_gdrdrv}
              label="GDRCopy Version"
            />
          <% end %>

          <%= if @form[:vgpu_device_manager_enabled].value do %>
            <.image_version
              field={@form[:vgpu_device_manager_image_tag_override]}
              image_id={:nvidia_vgpu_device_manager}
              label="vGPU Device Manager Version"
            />
          <% end %>

          <%= if @form[:sandbox_device_plugin_enabled].value do %>
            <.image_version
              field={@form[:kubevirt_gpu_device_plugin_image_tag_override]}
              image_id={:nvidia_kubevirt_gpu_device_plugin}
              label="KubeVirt Plugin Version"
            />
          <% end %>

          <%= if @form[:cc_manager_enabled].value do %>
            <.image_version
              field={@form[:k8s_cc_manager_image_tag_override]}
              image_id={:nvidia_k8s_cc_manager}
              label="Confidential Computing Version"
            />
          <% end %>

          <%= if @form[:kata_manager_enabled].value do %>
            <.image_version
              field={@form[:k8s_kata_manager_image_tag_override]}
              image_id={:nvidia_k8s_kata_manager}
              label="Kata Manager Version"
            />
          <% end %>

          <%= if @form[:vfio_manager_enabled].value do %>
            <.image_version
              field={@form[:cuda_image_tag_override]}
              image_id={:nvidia_cuda}
              label="CUDA Version"
            />
          <% end %>

          <%= if @form[:node_status_exporter_enabled].value do %>
            <.image_version
              field={@form[:gpu_operator_validator_image_tag_override]}
              image_id={:nvidia_gpu_operator_validator}
              label="Validator Version"
            />
          <% end %>

          <.image_version
            field={@form[:k8s_driver_manager_image_tag_override]}
            image_id={:nvidia_k8s_driver_manager}
            label="Driver Manager Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
