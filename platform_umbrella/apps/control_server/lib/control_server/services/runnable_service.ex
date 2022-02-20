defmodule ControlServer.Services.RunnableService do
  alias ControlServer.Services

  @enforce_keys [:service_type, :path]
  defstruct service_type: nil, path: nil, config: %{}

  def services,
    do: [
      # Battery
      %__MODULE__{path: "/battery/core", service_type: :battery},
      %__MODULE__{path: "/battery/control_server", service_type: :control_server},
      %__MODULE__{path: "/battery/echo", service_type: :echo_server},

      # Devtools
      %__MODULE__{path: "/devtools/knative", service_type: :knative},

      # Database
      %__MODULE__{path: "/database/common", service_type: :database},
      %__MODULE__{path: "/database/public", service_type: :database_public},
      %__MODULE__{path: "/battery/database", service_type: :database_internal},
      %__MODULE__{path: "/ml/notebooks", service_type: :notebooks},

      # Monitoring
      %__MODULE__{path: "/monitoring/prometheus_operator", service_type: :prometheus_operator},
      %__MODULE__{path: "/monitoring/prometheus", service_type: :prometheus},
      %__MODULE__{path: "/monitoring/grafana", service_type: :grafana},
      %__MODULE__{path: "/monitoring/alert_manager", service_type: :alert_manager},
      %__MODULE__{path: "/monitoring/kube_monitoring", service_type: :kube_monitoring},

      # Network
      %__MODULE__{path: "/network/kong", service_type: :kong},
      %__MODULE__{path: "/network/nginx", service_type: :nginx},
      %__MODULE__{path: "/network/istio", service_type: :istio},

      # Security
      %__MODULE__{path: "/security/cert_manager", service_type: :cert_manager}
    ]

  def services_map, do: services() |> Enum.map(fn s -> {s.service_type, s} end) |> Enum.into(%{})

  def activate!(service_type) when is_atom(service_type),
    do: services_map() |> Map.get(service_type) |> activate!()

  def activate!(%__MODULE__{path: path, service_type: service_type, config: config} = _service) do
    Services.find_or_create!(%{
      is_active: true,
      root_path: path,
      service_type: service_type,
      config: config
    })
  end

  def active?(path) when is_bitstring(path), do: Services.active?(path)

  def active?(service_type) when is_atom(service_type),
    do: services_map() |> Map.get(service_type) |> active?()

  def active?(%__MODULE__{path: path} = _service), do: Services.active?(path)
end
