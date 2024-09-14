defmodule ControlServerWeb.Batteries.BatteryCoreForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  alias CommonCore.Installs.Options
  alias CommonCore.Util.Time
  alias CommonUI.TextHelpers

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        <%= @battery.description %>
      </.panel>

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

      <.panel title="Namespaces">
        <.simple_form variant="nested">
          <.input field={@form[:core_namespace]} label="Core Namespace" />
          <.input field={@form[:base_namespace]} label="Base Namespace" />
          <.input field={@form[:data_namespace]} label="Data Namespace" />
          <.input field={@form[:ai_namespace]} label="AI Namespace" />
        </.simple_form>
      </.panel>

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

      <.panel title="Advanced" variant="gray">
        <.simple_form variant="nested">
          <div class="flex justify-between items-center">
            <div class="flex-1 text-sm">Secret Key</div>

            <div class="font-mono font-bold text-sm">
              <%= TextHelpers.obfuscate(@form[:secret_key].value, char_limit: 4) %>
            </div>
          </div>
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
