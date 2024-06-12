defmodule CommonCore.ET.InstallStatus do
  @moduledoc """
  This module is used to return the status of an installation.
  """
  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :status, Ecto.Enum,
      values: ~w(ok unknown needs_account needs_payment bad)a,
      default: :unknown

    field :message, :string
  end

  def status_ok?(%__MODULE__{status: :bad}), do: false
  def status_ok?(%__MODULE__{status: :needs_payment}), do: false
  def status_ok?(%__MODULE__{status: :needs_account}), do: false
  def status_ok?(_), do: true

  @doc ~S"""
  Returns the path to redirect to based on the status of
  the installation. This is to be used in the control server.

  ### Examples
      iex> InstallStatus.redirect_path(%InstallStatus{status: :needs_account})
      "/error/needs_account"

      iex> InstallStatus.redirect_path(%InstallStatus{status: :ok})
      nil
  """
  @spec redirect_path(t()) :: nil | binary()
  def redirect_path(_)

  def redirect_path(%__MODULE__{status: :needs_account}), do: "/error/needs_account"
  def redirect_path(%__MODULE__{status: :needs_payment}), do: "/error/needs_payment"
  def redirect_path(%__MODULE__{status: :bad}), do: "/error/bad"
  def redirect_path(_), do: nil
end
