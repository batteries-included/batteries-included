defmodule ControlServerWeb.Batteries.BatteryCoreForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  alias CommonCore.Installs.Options
  alias CommonCore.Util.Time
  alias CommonUI.TextHelpers

  def render(assigns) do
    ~H"""
    <div class="contents">
      <div>
        <.panel title="Upgrade Schedule">
          <.simple_form variant="nested">
            <.input
              type="multiselect"
              field={@form[:virtual_upgrade_days_of_week]}
              options={Time.days_of_week_options()}
            />

            <div class="flex gap-2">
              <.input
                field={@form[:upgrade_start_hour]}
                type="select"
                placeholder="Start Time"
                options={Time.time_options()}
              />

              <span>to</span>

              <.input
                field={@form[:upgrade_end_hour]}
                type="select"
                placeholder="End Time"
                options={Time.time_options()}
              />
            </div>
          </.simple_form>
        </.panel>
      </div>

      <div>
        <.panel title="Configuration">
          <.simple_form variant="nested">
            <.input field={@form[:cluster_name]} label="Cluster Name" />

            <.input
              field={@form[:cluster_type]}
              type="select"
              label="Cluster Type"
              options={Options.provider_options()}
            />

            <.input
              field={@form[:default_size]}
              type="select"
              label="Default Size"
              options={Options.size_options()}
            />

            <.input field={@form[:usage]} type="select" label="Usage" options={Options.usages()} />
          </.simple_form>
        </.panel>
      </div>

      <div>
        <.panel title="Namespaces">
          <.simple_form variant="nested">
            <.input field={@form[:core_namespace]} label="Core Namespace" />
            <.input field={@form[:base_namespace]} label="Base Namespace" />
            <.input field={@form[:data_namespace]} label="Data Namespace" />
            <.input field={@form[:ai_namespace]} label="AI Namespace" />
          </.simple_form>
        </.panel>
      </div>

      <div>
        <.panel title="Secret Key">
          <div class="flex flex-wrap items-center justify-between gap-4">
            <div class="flex-1 font-mono font-bold text-sm">
              <%= TextHelpers.obfuscate(@form[:secret_key].value) %>
            </div>

            <%!-- <.button>Regenerate</.button> --%>
          </div>
        </.panel>
      </div>

      <div>
        <.panel title="Advanced" variant="gray">
          <.simple_form variant="nested">
            <.input field={@form[:server_in_cluster]} type="switch" label="Server In Cluster" />
          </.simple_form>
        </.panel>
      </div>
    </div>
    """
  end
end
