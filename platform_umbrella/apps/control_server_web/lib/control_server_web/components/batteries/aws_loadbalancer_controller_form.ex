defmodule ControlServerWeb.Batteries.AWSLoadBalancerControllerForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  alias CommonCore.Defaults.Images

  def render(assigns) do
    ~H"""
    <div class="contents">
      <div>
        <.panel title="Configuration">
          <.simple_form variant="nested">
            <.input field={@form[:service_role_arn]} label="Service Role ARN" autocomplete="off" />
          </.simple_form>
        </.panel>
      </div>

      <div>
        <.panel title="Image">
          <.simple_form variant="nested">
            <.input
              field={@form[:image_version]}
              type="select"
              label="Version"
              placeholder="Choose a version"
              options={Images.get_versions(:aws_load_balancer_controller)}
            />

            <.image form={@form} />
          </.simple_form>
        </.panel>
      </div>
    </div>
    """
  end
end
