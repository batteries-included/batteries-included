defmodule ControlServerWeb.Batteries.AWSLoadBalancerControllerForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  alias Ecto.Changeset

  def handle_event("add_subnet", _params, socket) do
    add_item_to_list(socket, :subnets)
  end

  def handle_event("remove_subnet", %{"index" => index}, socket) do
    remove_item_from_list(socket, :subnets, index)
  end

  def handle_event("add_eip", _params, socket) do
    add_item_to_list(socket, :eip_allocations)
  end

  def handle_event("remove_eip", %{"index" => index}, socket) do
    remove_item_from_list(socket, :eip_allocations, index)
  end

  defp add_item_to_list(socket, name) do
    items = Changeset.get_field(socket.assigns.form.source, name) || []

    form =
      socket.assigns.form.source
      |> Changeset.put_change(name, items ++ [""])
      |> to_form(as: socket.assigns.form.name)

    {:noreply, assign(socket, :form, form)}
  end

  defp remove_item_from_list(socket, name, index) do
    items =
      socket.assigns.form.source
      |> Changeset.get_field(name)
      |> List.delete_at(String.to_integer(index))

    form =
      socket.assigns.form.source
      |> Changeset.put_change(name, items)
      |> to_form(as: socket.assigns.form.name)

    {:noreply, assign(socket, :form, form)}
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        <%= @battery.description %>
      </.panel>

      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:service_role_arn]} label="Service Role ARN" />

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
        </.simple_form>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:image].value %></.image>

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:aws_load_balancer_controller}
            label="Version"
          />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
