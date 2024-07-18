defmodule ControlServerWeb.TraditionalServices.TraditionalServicesTest do
  use ControlServerWeb.IntegrationTestCase

  @service_name "int-test-creation"

  feature "Can start a Traditional Service", %{session: session} do
    service_name = "#{@service_name}-#{:rand.uniform(10_000)}"

    session
    |> visit("/traditional_services/new")
    |> assert_text("New Traditional Service")
    |> fill_in(text_field("service[name]"), with: service_name)
    |> click(button("Add Container"))
    |> assert_text("Name")
    |> assert_text("Image")
    |> assert_text("Command")
    |> fill_in(text_field("container[name]"), with: "main")
    |> fill_in(text_field("container[image]"), with: "nginx:latest")
    |> click(css("#container-form button[type=submit]"))
    |> click(button("Save"))
  end
end