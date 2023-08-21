defmodule ControlServerWeb.Live.TrivyReportShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  import CommonUI.Table

  alias KubeServices.KubeState

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"resource_type" => report_type, "namespace" => namespace, "name" => name}, _, socket) do
    report_type_atom = String.to_existing_atom(report_type)
    report = report(report_type_atom, namespace, name)

    {:noreply,
     socket
     |> assign_report(report)
     |> assign_title("Trivy Report")
     |> assign_report_type(report_type_atom)
     |> assign_name(name)}
  end

  def assign_title(socket, page_title) do
    assign(socket, :page_title, page_title)
  end

  def assign_name(socket, name) do
    assign(socket, :name, name)
  end

  def assign_report_type(socket, report_type) do
    assign(socket, :report_type, report_type)
  end

  def assign_report(socket, report) do
    assign(socket, :report, report)
  end

  def report(type, namespace, name), do: KubeState.get!(type, namespace, name)

  @impl Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <.h1>
      <%= @page_title %>
      <:sub_header><%= @report_type %></:sub_header>
    </.h1>
    <.h2><%= @name %></.h2>
    <div class="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-4">
      <.card>
        <:title>Artifact</:title>
        <div class="text-center">
          <%= get_in(@report, ~w(report artifact repository)) %>
        </div>
        <div class="text-center uppercase text-astral-500">
          <%= get_in(@report, ~w(report artifact tag)) %>
        </div>
      </.card>
      <.card>
        <:title>Registry</:title>
        <div class="text-center">
          <%= get_in(@report, ~w(report registry server)) %>
        </div>
      </.card>
      <.card>
        <:title>Scanner</:title>
        <div class="text-center">
          <%= get_in(@report, ~w(report scanner name)) %>
        </div>
        <div class="text-center text-astral-500">
          <%= get_in(@report, ~w(report scanner version)) %>
        </div>
      </.card>
    </div>
    <.card>
      <.table rows={get_in(@report, ~w(report vulnerabilities))}>
        <:col :let={vuln} label="Severity"><%= get_in(vuln, ~w(severity)) %></:col>
        <:col :let={vuln} label="Title">
          <.a href={get_in(vuln, ~w(primaryLink))}>
            <%= get_in(vuln, ~w(title)) %>
          </.a>
        </:col>
        <:col :let={vuln} label="Used"><%= get_in(vuln, ~w(installedVersion)) %></:col>
        <:col :let={vuln} label="Fixed"><%= get_in(vuln, ~w(fixedVersion)) %></:col>
        <:action :let={vuln}>
          <.a href={get_in(vuln, ~w(primaryLink))} variant="styled">
            Show
          </.a>
        </:action>
      </.table>
    </.card>
    """
  end
end
