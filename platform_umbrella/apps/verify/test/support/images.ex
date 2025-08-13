defmodule Verify.Images do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      @echo_server "ealen/echo-server:latest"
      @victoria_metrics ~w(vm_operator vm_insert vm_select vm_storage vm_agent)a
      @cert_manager ~w(cert_manager_acmesolver cert_manager_cainjector cert_manager_controller cert_manager_webhook)a
    end
  end
end
