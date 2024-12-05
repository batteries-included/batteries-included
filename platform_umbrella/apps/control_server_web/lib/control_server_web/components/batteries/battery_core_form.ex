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
        {@battery.description}
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Cluster Name</:label>
            <.input field={@form[:cluster_name]} disabled={@action != :new} />
          </.field>

          <.field>
            <:label>Cluster Type</:label>
            <.input
              type="select"
              field={@form[:cluster_type]}
              options={Options.provider_options()}
              disabled={@action != :new}
            />
          </.field>

          <.field>
            <:label>Default Size</:label>
            <.input type="select" field={@form[:default_size]} options={Options.size_options()} />
          </.field>

          <.field>
            <:label>Usage</:label>
            <.input
              type="select"
              field={@form[:usage]}
              options={Options.usages()}
              disabled={@action != :new}
            />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Namespaces">
        <.fieldset>
          <.field>
            <:label>Core Namespace</:label>
            <.input field={@form[:core_namespace]} disabled={@action != :new} />
          </.field>

          <.field>
            <:label>Base Namespace</:label>
            <.input field={@form[:base_namespace]} disabled={@action != :new} />
          </.field>

          <.field>
            <:label>Data Namespace</:label>
            <.input field={@form[:data_namespace]} disabled={@action != :new} />
          </.field>

          <.field>
            <:label>AI Namespace</:label>
            <.input field={@form[:ai_namespace]} disabled={@action != :new} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Upgrade Schedule">
        <.fieldset>
          <.input
            type="multiselect"
            field={@form[:virtual_upgrade_days_of_week]}
            options={Time.days_of_week_options()}
          />

          <div class="flex gap-2">
            <.input
              type="select"
              field={@form[:upgrade_start_hour]}
              placeholder="Start Time"
              options={Time.time_options()}
            />

            <span>to</span>

            <.input
              type="select"
              field={@form[:upgrade_end_hour]}
              placeholder="End Time"
              options={Time.time_options()}
            />
          </div>
        </.fieldset>
      </.panel>

      <.panel title="Advanced" variant="gray">
        <.fieldset>
          <div class="flex justify-between items-center">
            <div class="flex-1 text-sm">Secret Key</div>

            <div class="font-mono font-bold text-sm">
              {TextHelpers.obfuscate(@form[:secret_key].value, keep: 2, char_limit: 6)}
            </div>
          </div>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
