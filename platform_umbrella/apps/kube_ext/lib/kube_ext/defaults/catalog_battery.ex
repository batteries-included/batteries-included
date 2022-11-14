defmodule KubeExt.Defaults.CatalogBattery do
  @enforce_keys [:type, :group]
  defstruct type: nil,
            group: nil,
            config: %{},
            dependencies: []
end
