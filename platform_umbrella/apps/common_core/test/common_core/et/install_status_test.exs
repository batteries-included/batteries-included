defmodule CommonCore.ET.InstallStatusTest do
  use ExUnit.Case

  alias CommonCore.ET.InstallStatus

  doctest CommonCore.ET.InstallStatus

  describe "status_ok?/1" do
    test "returns false when status is :bad" do
      status = InstallStatus.new!(status: :bad)
      assert InstallStatus.status_ok?(status) == false
    end

    test "returns false when status is :needs_payment" do
      status = InstallStatus.new!(status: :needs_payment)
      assert InstallStatus.status_ok?(status) == false
    end

    test "returns false when status is :needs_account" do
      status = InstallStatus.new!(status: :needs_account)
      assert InstallStatus.status_ok?(status) == false
    end

    test "returns true when status is :ok" do
      # This is the best status
      status = InstallStatus.new!(status: :ok)
      assert InstallStatus.status_ok?(status) == true
    end

    test "returns true when status is :unknown" do
      # This is just while we try and figure out what the status is
      status = InstallStatus.new!(status: :unknown)
      assert InstallStatus.status_ok?(status) == true
    end
  end

  describe "redirect_path/1" do
    test "returns '/error/needs_account' when status is :needs_account" do
      status = InstallStatus.new!(status: :needs_account)
      assert InstallStatus.redirect_path(status) == "/error/needs_account"
    end

    test "returns nil when status is :ok" do
      status = InstallStatus.new!(status: :ok)
      assert InstallStatus.redirect_path(status) == nil
    end
  end
end
