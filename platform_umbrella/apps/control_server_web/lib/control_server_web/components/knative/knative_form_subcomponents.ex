defmodule ControlServerWeb.KnativeFormSubcomponents do
  use ControlServerWeb, :html

  import Phoenix.HTML.Form, only: [inputs_for: 2, input_value: 2]

  attr :containers_field, :atom, default: :containers
  attr :form, :any, required: true
  attr :target, :any, required: true

  def containers_form(assigns) do
    ~H"""
    <div class="sm:col-span-2">
      <div class="flex flex-col gap-8">
        <%= for container_form <- inputs_for(@form, @containers_field) do %>
          <.single_container_form
            form={container_form}
            containers_field={@containers_field}
            target={@target}
          />
        <% end %>

        <.a
          phx-click="add:container"
          phx-target={@target}
          phx-value-containers-field={@containers_field}
          variant="styled"
        >
          <Heroicons.plus_circle class="w-6 inline-flex" /> Add Container
        </.a>
      </div>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :target, :any, required: true

  def env_values_form(assigns) do
    ~H"""
    <div class="sm:col-span-2">
      <div class="flex flex-col gap-8">
        <%= for env_form <- inputs_for(@form, :env_values) do %>
          <.single_env_value_form form={env_form} target={@target} />
        <% end %>

        <.a phx-click="add:env_value" phx-target={@target} variant="styled">
          <Heroicons.plus_circle class="w-6 inline-flex" />
          <span>Add Env</span>
        </.a>
      </div>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :target, :any, required: true
  attr :containers_field, :atom, required: true

  def single_container_form(assigns) do
    ~H"""
    <div class="grid grid-cols-12 gap-4">
      <div class="col-span-5">
        <.input field={{@form, :name}} label="Name" />
      </div>
      <div class="col-span-5">
        <.input field={{@form, :image}} label="Image" />
      </div>
      <div class="col-span-2 mx-auto my-auto">
        <.a
          phx-click="del:container"
          phx-value-idx={@form.index}
          phx-target={@target}
          phx-value-containers-field={@containers_field}
          variant="styled"
        >
          <Heroicons.trash class="w-6 inline-flex" /> Remove Container
        </.a>
      </div>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :target, :any, required: true

  def single_env_value_form(assigns) do
    ~H"""
    <div class="grid grid-cols-12 gap-4">
      <div class="col-span-5">
        <.input field={{@form, :name}} label="Name" />
      </div>
      <div class="col-span-5">
        <.input
          field={{@form, :source_type}}
          type="select"
          label="Source Type"
          prompt="Select a source"
          options={[:value, :config, :secret]}
        />
      </div>
      <div class="col-span-2 mx-auto my-auto">
        <.a
          phx-click="del:env_value"
          phx-value-idx={@form.index}
          phx-target={@target}
          variant="styled"
        >
          <Heroicons.trash class="w-6 inline-flex" /> Remove Env
        </.a>
      </div>
      <.env_value_body form={@form} source={input_value(@form, :source_type)} />
    </div>
    """
  end

  defp env_value_body(%{source: :value} = assigns) do
    ~H"""
    <div class="col-span-12">
      <.input field={{@form, :value}} label="Value" />
    </div>
    """
  end

  defp env_value_body(%{source: :config} = assigns) do
    ~H"""
    <div class="col-span-6">
      <.input field={{@form, :source_name}} label="Configmap Name" />
    </div>
    <div class="col-span-5">
      <.input field={{@form, :source_key}} label="Key" />
    </div>
    <div class="col-span-1">
      <.input field={{@form, :source_optiona}} label="Optional" type="checkbox" />
    </div>
    """
  end

  defp env_value_body(%{source: :secret} = assigns) do
    ~H"""
    <div class="col-span-6">
      <.input field={{@form, :source_name}} label="Secret Name" />
    </div>
    <div class="col-span-5">
      <.input field={{@form, :source_key}} label="Key" />
    </div>
    <div class="col-span-1">
      <.input field={{@form, :source_optiona}} label="Optional" type="checkbox" />
    </div>
    """
  end

  defp env_value_body(%{source: _} = assigns), do: ~H||
end
