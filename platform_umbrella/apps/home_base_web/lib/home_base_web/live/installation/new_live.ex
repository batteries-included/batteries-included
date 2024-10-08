defmodule HomeBaseWeb.InstallationNewLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  alias CommonCore.Installation
  alias Ecto.Changeset
  alias HomeBase.CustomerInstalls
  alias HomeBaseWeb.UserAuth

  def mount(_params, _session, socket) do
    owner = UserAuth.current_team_or_user(socket)
    installations = CustomerInstalls.list_installations(owner)
    changeset = CustomerInstalls.change_installation(%Installation{})

    {:ok,
     socket
     |> assign(:page, :installations)
     |> assign(:page_title, "Installations")
     |> assign(:default_size_dirty, false)
     |> assign(:installations, installations)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("change-default-size", params, socket) do
    socket = assign(socket, :default_size_dirty, true)

    handle_event("validate", params, socket)
  end

  def handle_event("validate", %{"installation" => params}, socket) do
    params = Map.merge(socket.assigns.form.source.params, params)

    changeset =
      %Installation{}
      |> Installation.changeset(params)
      |> Map.put(:action, :validate)

    changeset =
      if socket.assigns.default_size_dirty do
        changeset
      else
        put_recommended_size(changeset)
      end

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"installation" => params}, socket) do
    owner = UserAuth.current_team_or_user(socket)
    owner_key = if socket.assigns.current_role, do: "team_id", else: "user_id"
    params = Map.put(params, owner_key, owner.id)

    case CustomerInstalls.create_installation(params) do
      {:ok, installation} ->
        {:noreply, push_navigate(socket, to: ~p"/installations/#{installation}/success")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} id="new-installation-form" phx-change="validate" phx-submit="save">
      <div class="flex items-center justify-between mb-2">
        <.h2>Create a new installation</.h2>

        <.button type="submit" variant="primary" icon={:arrow_right} icon_position={:right}>
          Create Installation
        </.button>
      </div>

      <div class="grid lg:grid-cols-[2fr,1fr] content-start flex-1 gap-4">
        <.flex column>
          <.input_panel title="Name your installation">
            <.input field={@form[:slug]} placeholder="Choose a name" />
          </.input_panel>

          <.input_panel
            title="What is this for?"
            description="Aliqua velit deserunt fugiat esse aute cillum exercitation duis pariatur mollit et ad officia Lorem."
          >
            <.input
              field={@form[:usage]}
              type="select"
              placeholder="Select usage type"
              options={CommonCore.Installs.Options.usage_options(@current_role)}
            />
          </.input_panel>

          <.input_panel
            title="What provider will you use?"
            description="Aliqua velit deserunt fugiat esse aute cillum exercitation duis pariatur mollit et ad officia Lorem."
          >
            <.input
              field={@form[:kube_provider]}
              type="select"
              placeholder="Choose a provider"
              options={CommonCore.Installs.Options.provider_options(@form[:usage].value)}
            />
          </.input_panel>

          <.input_panel
            title="What instance size should we default to?"
            description={"This can still be customized for individual resources when they are created.#{if !@default_size_dirty, do: " We've preselected the recommended size for your usage type and provider."}"}
          >
            <.input
              field={@form[:default_size]}
              type="select"
              options={CommonCore.Installs.Options.size_options()}
              phx-change="change-default-size"
            />
          </.input_panel>
        </.flex>

        <.panel>
          <.markdown content={explanation(@form)} />
        </.panel>
      </div>
    </.form>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, default: nil
  slot :inner_block

  defp input_panel(assigns) do
    ~H"""
    <.panel>
      <div class={[
        "grid grid-cols-1 lg:grid-cols-2 gap-x-10 gap-y-4",
        !@description && "items-center"
      ]}>
        <.flex column gaps={2}>
          <p class="font-bold leading-tight"><%= @title %></p>
          <.light_text :if={@description} class="max-w-md"><%= @description %></.light_text>
        </.flex>

        <%= render_slot(@inner_block) %>
      </div>
    </.panel>
    """
  end

  def explanation(form) do
    ~s"""
    # What will this do, exactly?

    Once the installation is created, we'll generate a script for you to run in your local or cloud environment.

    #{explanation_more(form[:usage].value, form[:kube_provider].value)}
    """
  end

  def explanation_more(usage, provider) when is_binary(usage) do
    explanation_more(String.to_existing_atom(usage), provider)
  end

  def explanation_more(usage, provider) when is_binary(provider) do
    explanation_more(usage, String.to_existing_atom(provider))
  end

  def explanation_more(:development, :kind) do
    "TODO: Description about kind installations in development"
  end

  def explanation_more(:kitchen_sink, :kind) do
    "TODO: Description about kind installations in kitchen sink"
  end

  def explanation_more(:internal_dev, :kind) do
    "TODO: Description about kind installations in internal dev"
  end

  def explanation_more(:development, :aws) do
    "TODO: Description about aws installations in development"
  end

  def explanation_more(:production, :aws) do
    "TODO: Description about aws installations in production"
  end

  def explanation_more(:kitchen_sink, :aws) do
    "TODO: Description about aws installations in kitchen sink"
  end

  def explanation_more(:internal_dev, :aws) do
    "TODO: Description about aws installations in internal dev"
  end

  def explanation_more(:development, :provided) do
    "TODO: Description about provided installations in development"
  end

  def explanation_more(:production, :provided) do
    "TODO: Description about provided installations in production"
  end

  def explanation_more(:kitchen_sink, :provided) do
    "TODO: Description about provided installations in kitchen sink"
  end

  def explanation_more(:internal_dev, :provided) do
    "TODO: Description about provided installations in internal dev"
  end

  def explanation_more(_, _), do: ""

  defp put_recommended_size(changeset) do
    provider = Changeset.get_field(changeset, :kube_provider)
    usage = Changeset.get_field(changeset, :usage)

    Changeset.put_change(changeset, :default_size, recommended_size(provider, usage))
  end

  defp recommended_size(:kind, :kitchen_sink), do: :tiny
  defp recommended_size(:kind, :development), do: :small
  defp recommended_size(:aws, :kitchen_sink), do: :medium
  defp recommended_size(:aws, :development), do: :medium
  defp recommended_size(:aws, :production), do: :large
  defp recommended_size(:provided, :kitchen_sink), do: :medium
  defp recommended_size(:provided, :development), do: :medium
  defp recommended_size(:provided, :production), do: :large
  defp recommended_size(_, _), do: :medium
end
