defmodule KubeExt.ExampleGenerator do
  use KubeExt.ResourceGenerator
  alias KubeExt.ExampleSettings, as: Settings
  alias KubeExt.Builder, as: B

  resource(:main, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.name("main")
    |> B.namespace(namespace)
  end
end
