defmodule ControlServerWeb.PostgresFormSubcomponents do
  use ControlServerWeb, :html
  import Phoenix.HTML.Form, only: [inputs_for: 2]

  alias CommonCore.Postgres.PGCredentialCopy

  def users_form(assigns) do
    ~H"""
    <.card class="col-span-2">
      <:title>Users</:title>
      <div class="grid grid-cols-12 gap-4 sm:gap-8">
        <%= for user_form <- inputs_for(@form, :users) do %>
          <div class="col-span-4">
            <.input field={{user_form, :username}} label="Username" placeholder="Username" />
          </div>
          <div class="col-span-7">
            <.input
              field={{user_form, :roles}}
              label="Roles"
              type="multicheck"
              options={CommonCore.Postgres.possible_roles()}
            />
          </div>
          <div class="col-span-1">
            <.link
              phx-click="del:user"
              phx-value-idx={user_form.index}
              phx-target={@target}
              class="text-sm"
              variant="styled"
            >
              <Heroicons.trash class="w-7 h-7 mx-auto mt-8" />
            </.link>
          </div>
        <% end %>

        <.link
          phx-click="add:user"
          phx-target={@target}
          class="pt-5 text-lg col-span-12"
          variant="styled"
        >
          Add User
        </.link>
      </div>
    </.card>
    """
  end

  def databases_form(assigns) do
    ~H"""
    <.card class="col-span-2">
      <:title>Database</:title>
      <div class="grid grid-cols-12 gap-y-6 gap-x-4">
        <%= for database_form <- inputs_for(@form, :databases) do %>
          <div class="col-span-4">
            <.input field={{database_form, :name}} label="Name" />
          </div>
          <div class="col-span-7">
            <.input
              field={{database_form, :owner}}
              label="Owner"
              type="select"
              options={@possible_owners}
            />
          </div>
          <div class="col-span-1">
            <.link
              phx-click="del:database"
              phx-value-idx={database_form.index}
              phx-target={@target}
              class="text-sm"
              variant="styled"
            >
              <Heroicons.trash class="w-7 h-7 mx-auto mt-8" />
            </.link>
          </div>
        <% end %>

        <.link
          phx-click="add:database"
          phx-target={@target}
          class="pt-5 text-lg col-span-12"
          variant="styled"
        >
          Add Database
        </.link>
      </div>
    </.card>
    """
  end

  def credential_copies_form(assigns) do
    ~H"""
    <.card class="col-span-2">
      <:title>Credential Secret Copies</:title>
      <div class="grid grid-cols-12 gap-y-6 gap-x-4">
        <%= for credential_form <- inputs_for(@form, :credential_copies) do %>
          <div class="col-span-4">
            <.input
              field={{credential_form, :username}}
              label="Username"
              type="select"
              options={@possible_owners}
            />
          </div>
          <div class="col-span-4">
            <.input
              field={{credential_form, :namespace}}
              label="Namespace"
              type="select"
              options={@possible_namespaces}
            />
          </div>
          <div class="col-span-3">
            <.input
              field={{credential_form, :format}}
              label="Format"
              type="select"
              options={PGCredentialCopy.possible_formats()}
            />
          </div>
          <div class="col-span-1">
            <.link
              phx-click="del:credential_copy"
              phx-value-idx={credential_form.index}
              phx-target={@target}
              class="text-sm"
              variant="styled"
            >
              <Heroicons.trash class="w-7 h-7 mx-auto mt-8" />
            </.link>
          </div>
        <% end %>

        <.link
          phx-click="add:credential_copy"
          phx-target={@target}
          class="pt-5 text-lg col-span-12"
          variant="styled"
        >
          Add Copy of Credentials
        </.link>
      </div>
    </.card>
    """
  end
end
