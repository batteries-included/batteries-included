defmodule CommonUI.Form do
  use Phoenix.Component

  import PetalComponents.Helpers
  alias Phoenix.HTML.Form, as: PhoenixForm

  @wrapper_class "form-control w-full"

  def field_label(assigns) do
    base_classes = label_classes()

    assigns =
      assigns
      |> assign_defaults(base_classes)
      |> assign_new(:span_classes, fn -> "label-text text-lg" end)
      |> assign_new(:label, fn ->
        if assigns[:field] do
          PhoenixForm.humanize(assigns[:field])
        else
          nil
        end
      end)

    ~H"""
    <%= PhoenixForm.label @form, @field, [class: @classes, phx_feedback_for: PhoenixForm.input_name(@form, @field)] ++ @extra_assigns do %>
      <span class={@span_classes}><%= @label %></span>
    <% end %>
    """
  end

  def form_control(assigns) do
    assigns = assign_new(assigns, :class, fn -> @wrapper_class end)

    ~H"""
    <div class={@class}>
      <%= if @inner_block do %>
        <%= render_slot(@inner_block) %>
      <% end %>
    </div>
    """
  end

  def text_input(assigns) do
    base_classes = text_classes()
    error_classes = text_error_classes()
    assigns = assigns |> assign_defaults(base_classes) |> add_error(error_classes)

    ~H"""
    <.form_control class={@wrapper_class}>
      <.field_label form={@form} field={@field} />
      <%= PhoenixForm.text_input(
        @form,
        @field,
        [class: @classes, phx_feedback_for: PhoenixForm.input_name(@form, @field)] ++ @extra_assigns
      ) %>

      <%= if @has_errors do %>
        <.error_labels form={@form} field={@field} />
      <% end %>
    </.form_control>
    """
  end

  defp error_labels(assigns) do
    ~H"""
    <%= for {msg, _opts} <- Keyword.get_values(@form.errors, @field) do %>
      <.field_label
        form={@form}
        field={@field}
        span_classes="label-text-alt italic text-heath-300"
        label={msg}
      />
    <% end %>
    """
  end

  def range_input(assigns) do
    base_classes = range_classes()
    assigns = assign_defaults(assigns, base_classes)

    ~H"""
    <.form_control class={@wrapper_class}>
      <.field_label form={@form} field={@field} />
      <%= PhoenixForm.range_input(
        @form,
        @field,
        [class: @classes, phx_feedback_for: PhoenixForm.input_name(@form, @field)] ++ @extra_assigns
      ) %>

      <%= if @has_errors do %>
        <.error_labels form={@form} field={@field} />
      <% end %>
    </.form_control>
    """
  end

  def switch_input(assigns) do
    base_classes = switch_classes()
    assigns = assign_defaults(assigns, base_classes)

    ~H"""
    <.form_control class={@wrapper_class}>
      <.field_label form={@form} field={@field} />
      <%= PhoenixForm.checkbox(
        @form,
        @field,
        [class: @classes, phx_feedback_for: PhoenixForm.input_name(@form, @field)] ++ @extra_assigns
      ) %>

      <%= if @has_errors do %>
        <.error_labels form={@form} field={@field} />
      <% end %>
    </.form_control>
    """
  end

  defp assign_defaults(assigns, base_classes) do
    assigns
    |> assign_new(:extra_assigns, fn ->
      assigns_to_attributes(assigns, [
        :class,
        :label,
        :form,
        :field,
        :type,
        :options,
        :layout
      ])
    end)
    |> assign_new(:classes, fn ->
      build_class([
        base_classes,
        assigns[:class]
      ])
    end)
    |> assign_new(:has_errors, fn -> has_errors?(assigns) end)
    |> assign_new(:wrapper_class, fn -> @wrapper_class end)
  end

  defp add_error(%{has_errors: true, classes: classes} = assigns, error_class) do
    assign(assigns, :classes, build_class([classes, error_class]))
  end

  defp add_error(assigns, _error_class), do: assigns

  defp text_classes do
    "input input-bordered w-full"
  end

  defp text_error_classes do
    "input-error bg-heath-300/10"
  end

  defp label_classes do
    "label"
  end

  defp range_classes do
    "range range-secondary"
  end

  defp switch_classes do
    "toggle toggle-secondary toggle-lg"
  end

  defp has_errors?(%{form: form, field: field}) do
    length(Keyword.get_values(form.errors, field)) > 0
  end

  defp has_errors?(_), do: false
end
