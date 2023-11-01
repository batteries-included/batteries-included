defmodule CommonCore.Resources.FieldAccessorsTest do
  use ExUnit.Case

  import CommonCore.Resources.FieldAccessors

  test "uid/1 returns the UID from the resource" do
    resource = %{"metadata" => %{"uid" => "abc123"}}
    assert uid(resource) == "abc123"
  end

  test "uid/1 returns nil if no UID exists" do
    resource = %{}
    assert uid(resource) == nil
  end

  test "conditions/1 returns conditions list" do
    resource = %{"status" => %{"conditions" => [%{type: "Ready"}]}}
    assert length(conditions(resource)) == 1
  end

  test "conditions/1 returns empty list if no conditions exist" do
    resource = %{}
    assert conditions(resource) == []
  end

  test "phase/1 returns the phase" do
    resource = %{"status" => %{"phase" => "Pending"}}
    assert phase(resource) == "Pending"
  end

  test "phase/1 returns nil if no phase exists" do
    resource = %{}
    assert phase(resource) == nil
  end

  test "replicas/1 returns the replica count" do
    resource = %{"spec" => %{"replicas" => 3}}
    assert replicas(resource) == 3
  end

  test "replicas/1 returns nil if no replicas exist" do
    resource = %{}
    assert replicas(resource) == nil
  end

  test "available_replicas/1 returns the available replica count" do
    resource = %{"status" => %{"availableReplicas" => 2}}
    assert available_replicas(resource) == 2
  end

  test "available_replicas/1 returns nil if no available replica count exists" do
    resource = %{}
    assert available_replicas(resource) == nil
  end
end
