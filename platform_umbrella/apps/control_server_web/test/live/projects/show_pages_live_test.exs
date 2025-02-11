defmodule ControlServerWeb.Projects.ShowPagesLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  setup do
    project = insert(:project)

    postgres_cluster = insert(:postgres_cluster, project_id: project.id)
    redis_instance = insert(:redis_cluster, project_id: project.id)
    jupyter_notebook = insert(:jupyter_lab_notebook, project_id: project.id)
    knative_service = insert(:knative_service, project_id: project.id)
    traditional_service = insert(:traditional_service, project_id: project.id)

    %{
      project: project,
      postgres_cluster: postgres_cluster,
      redis_instance: redis_instance,
      jupyter_notebook: jupyter_notebook,
      knative_service: knative_service,
      traditional_service: traditional_service
    }
  end

  describe "the project show page" do
    test "show page renders", %{conn: conn, project: project} do
      conn
      |> start(~p|/projects/#{project.id}/show|)
      |> assert_html(project.name)
    end

    test "postgres_clusters page renders", %{conn: conn, project: project, postgres_cluster: pg} do
      conn
      |> start(~p|/projects/#{project.id}/postgres_clusters|)
      |> assert_html(pg.name)
    end

    test "redis_instances page renders", %{conn: conn, project: project, redis_instance: redis} do
      conn
      |> start(~p|/projects/#{project.id}/redis_instances|)
      |> assert_html(redis.name)
    end

    test "jupyter_notebooks page renders", %{conn: conn, project: project, jupyter_notebook: notebook} do
      conn
      |> start(~p|/projects/#{project.id}/jupyter_notebooks|)
      |> assert_html(notebook.name)
    end
  end
end
