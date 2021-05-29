defmodule HomeBase.BillingTest do
  use HomeBase.DataCase

  alias HomeBase.Billing

  describe "billing_reports" do
    alias HomeBase.Billing.BillingReport

    @valid_attrs %{
      end: "2010-04-17T14:00:00.000000Z",
      by_hour: %{},
      start: "2010-04-17T14:00:00.000000Z",
      node_hours: 42,
      pod_hours: 42
    }
    @update_attrs %{
      end: "2011-05-18T15:01:01.000000Z",
      by_hour: %{},
      start: "2011-05-18T15:01:01.000000Z",
      node_hours: 44,
      pod_hours: 45
    }
    @invalid_attrs %{end: nil, by_hour: nil, start: nil, node_hours: nil, pod_hours: nil}

    def billing_report_fixture(attrs \\ %{}) do
      {:ok, billing_report} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Billing.create_billing_report()

      billing_report
    end

    test "list_billing_reports/0 returns all billing_reports" do
      billing_report = billing_report_fixture()
      assert Billing.list_billing_reports() == [billing_report]
    end

    test "get_billing_report!/1 returns the billing_report with given id" do
      billing_report = billing_report_fixture()
      assert Billing.get_billing_report!(billing_report.id) == billing_report
    end

    test "create_billing_report/1 with valid data creates a billing_report" do
      assert {:ok, %BillingReport{} = billing_report} =
               Billing.create_billing_report(@valid_attrs)

      assert billing_report.end ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00.000000Z], "Etc/UTC")

      assert billing_report.by_hour == %{}

      assert billing_report.start ==
               DateTime.from_naive!(~N[2010-04-17T14:00:00.000000Z], "Etc/UTC")

      assert billing_report.node_hours == 42
      assert billing_report.pod_hours == 42
    end

    test "create_billing_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Billing.create_billing_report(@invalid_attrs)
    end

    test "update_billing_report/2 with valid data updates the billing_report" do
      billing_report = billing_report_fixture()

      assert {:ok, %BillingReport{} = billing_report} =
               Billing.update_billing_report(billing_report, @update_attrs)

      assert billing_report.end ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01.000000Z], "Etc/UTC")

      assert billing_report.by_hour == %{}

      assert billing_report.start ==
               DateTime.from_naive!(~N[2011-05-18T15:01:01.000000Z], "Etc/UTC")

      assert billing_report.node_hours == 44
      assert billing_report.pod_hours == 45
    end

    test "update_billing_report/2 with invalid data returns error changeset" do
      billing_report = billing_report_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Billing.update_billing_report(billing_report, @invalid_attrs)

      assert billing_report == Billing.get_billing_report!(billing_report.id)
    end

    test "delete_billing_report/1 deletes the billing_report" do
      billing_report = billing_report_fixture()
      assert {:ok, %BillingReport{}} = Billing.delete_billing_report(billing_report)
      assert_raise Ecto.NoResultsError, fn -> Billing.get_billing_report!(billing_report.id) end
    end

    test "change_billing_report/1 returns a billing_report changeset" do
      billing_report = billing_report_fixture()
      assert %Ecto.Changeset{} = Billing.change_billing_report(billing_report)
    end

    test "generated_a_good_billing_report" do
    end
  end
end
