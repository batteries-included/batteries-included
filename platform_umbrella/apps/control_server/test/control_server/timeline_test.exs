defmodule ControlServer.TimelineTest do
  use ControlServer.DataCase

  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.TimelineEvent
  alias ControlServer.Timeline

  describe "timeline_events" do
    import ControlServer.TimelineFixtures

    alias EventCenter.Database, as: DatabaseEventCenter

    @invalid_attrs %{payload: nil, type: nil}

    test "Can create changeset for TimelineEvent with a poly embed" do
      event = %TimelineEvent{
        type: :battery_install,
        payload: %BatteryInstall{battery_type: :cloudnative_pg_cluster}
      }

      assert _ = TimelineEvent.changeset(event, %{})
    end

    test "Can create a battery_install event" do
      event = Timeline.battery_install_event(:cloudnative_pg)
      assert {:ok, _} = Timeline.create_timeline_event(event)
    end

    test "Can create a kube event" do
      event = Timeline.kube_event(:add, :pod, "pg-control-0", "battery-core")
      assert {:ok, inserted_event} = Timeline.create_timeline_event(event)
      assert inserted_event.payload.resource_type == :pod
    end

    test "Can create a database event" do
      event = Timeline.named_database_event(:update, :cloudnative_pg_cluster, "pg-control", "00-01-02-03-04")
      assert {:ok, inserted_event} = Timeline.create_timeline_event(event)
      assert inserted_event.payload.schema_type == :cloudnative_pg_cluster
    end

    test "get database message for events" do
      DatabaseEventCenter.subscribe(:timeline_event)

      assert {:ok, _} =
               Timeline.create_timeline_event(Timeline.kube_event(:add, :pod, "pg-control-0", "battery-core"))

      assert_receive {:insert, _}
    end

    test "list_timeline_events/0 returns limited timeline_events" do
      _ = timeline_event_fixture()
      timeline_event_1 = timeline_event_fixture()
      assert Timeline.list_timeline_events(1) == [timeline_event_1]
    end

    test "get_timeline_event!/1 returns the timeline_event with given id" do
      timeline_event = timeline_event_fixture()
      assert Timeline.get_timeline_event!(timeline_event.id) == timeline_event
    end

    test "create_timeline_event/1 with valid data creates a timeline_event" do
      valid_attrs = %{type: :battery_install, payload: %{type: :battery_install, battery_type: :grafana}}

      assert {:ok, %TimelineEvent{} = timeline_event} =
               Timeline.create_timeline_event(valid_attrs)

      assert timeline_event.payload.battery_type == :grafana
    end

    test "create_timeline_event/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Timeline.create_timeline_event(@invalid_attrs)
    end

    test "update_timeline_event/2 with invalid data returns error changeset" do
      timeline_event = timeline_event_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Timeline.update_timeline_event(timeline_event, @invalid_attrs)

      assert timeline_event == Timeline.get_timeline_event!(timeline_event.id)
    end

    test "delete_timeline_event/1 deletes the timeline_event" do
      timeline_event = timeline_event_fixture()
      assert {:ok, %TimelineEvent{}} = Timeline.delete_timeline_event(timeline_event)
      assert_raise Ecto.NoResultsError, fn -> Timeline.get_timeline_event!(timeline_event.id) end
    end

    test "change_timeline_event/1 returns a timeline_event changeset" do
      timeline_event = timeline_event_fixture()
      assert %Ecto.Changeset{} = Timeline.change_timeline_event(timeline_event)
    end
  end
end
