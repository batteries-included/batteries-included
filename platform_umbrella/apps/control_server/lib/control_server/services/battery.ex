defmodule ControlServer.Services.Battery do
  alias ControlServer.Services

  @default_path "/battery"

  def activate!(path \\ @default_path) do
    Services.find_or_create!(%{
      is_active: true,
      root_path: path,
      service_type: :battery,
      config: default_config()
    })
  end

  def active?(path \\ @default_path), do: Services.active?(path)

  defp default_config do
    %{
      "control.run" => control_run?()
    }
  end

  defp control_run? do
    :control_server
    |> Application.get_env(ControlServer.Services)
    |> Keyword.get(:control_run, false)
  end
end
