defmodule KubeExt.ExampleGenerator do
  use KubeExt.ResourceGenerator
  alias KubeExt.ExampleSettings, as: Settings

  resource(:main, config) do
    namespace = Settings.namespace(config)

    B.build_resource(:service_account)
    |> B.name("main")
    |> B.namespace(namespace)
  end
end
