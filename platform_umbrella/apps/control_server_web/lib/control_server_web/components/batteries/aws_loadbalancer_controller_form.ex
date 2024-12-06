defmodule ControlServerWeb.Batteries.AWSLoadBalancerControllerForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import CommonCore.Ecto.Validations
  import ControlServerWeb.BatteriesFormSubcomponents

  def handle_event("add_subnet", _params, socket) do
    socket.assigns.form.source
    |> add_item_to_list(:subnets)
    |> assign_form(socket)
  end

  def handle_event("remove_subnet", %{"index" => index}, socket) do
    socket.assigns.form.source
    |> remove_item_from_list(:subnets, index)
    |> assign_form(socket)
  end

  def handle_event("add_eip", _params, socket) do
    socket.assigns.form.source
    |> add_item_to_list(:eip_allocations)
    |> assign_form(socket)
  end

  def handle_event("remove_eip", %{"index" => index}, socket) do
    socket.assigns.form.source
    |> remove_item_from_list(:eip_allocations, index)
    |> assign_form(socket)
  end

  defp assign_form(changeset, socket) do
    form = to_form(changeset, as: socket.assigns.form.name)

    {:noreply, assign(socket, :form, form)}
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        {@battery.description}
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>{@form[:image].value}</.image>

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:aws_load_balancer_controller}
            label="Version"
          />
        </.fieldset>
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Service Role ARN</:label>
            <.input field={@form[:service_role_arn]} />
          </.field>

          <.input_list
            :let={field}
            field={@form[:subnets]}
            label="Subnets"
            add_label="Add a subnet"
            add_click="add_subnet"
            remove_click="remove_subnet"
            phx_target={@myself}
          >
            <.input field={field} placeholder="Enter a subnet" />
          </.input_list>

          <.input_list
            :let={field}
            field={@form[:eip_allocations]}
            label="Elastic IPs"
            add_label="Add an Elastic IP"
            add_click="add_eip"
            remove_click="remove_eip"
            phx_target={@myself}
          >
            <.input field={field} placeholder="Enter an IP address" />
          </.input_list>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
