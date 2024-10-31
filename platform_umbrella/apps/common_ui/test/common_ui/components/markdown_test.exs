defmodule CommonUI.Components.MarkdownTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Markdown

  @simple_content "# Hello, World!"
  @with_code_content """
  Shows that quotes work in code blocks

  ```elixir
  defmodule Test do
    def test do
      IO.puts "Hello, World!"
    end
  end
  ```
  """
  @with_list_content """
  # List

  - Item 1
  - Item 2
  - Item 3
  """

  @with_complex_content """
  # Markdown

  This is a markdown component and it supports:

  - Lists
  - Headers
  - Inline Code `defmodule Test do`
  - Sub Header

  ## Sub Header

  ```
  auto test = 100;
  cout << test << endl;
  ```
  """

  @with_malicious_script """
  # Markdown

  <script>window.alert("hacker man")</script>
  """

  component_snapshot_test "renders markdown content" do
    assigns = %{content: @simple_content}

    ~H"""
    <.markdown content={@content} />
    """
  end

  component_snapshot_test "renders markdown content with code" do
    assigns = %{content: @with_code_content}

    ~H"""
    <.markdown content={@content} />
    """
  end

  component_snapshot_test "renders markdown content with list" do
    assigns = %{content: @with_list_content}

    ~H"""
    <.markdown content={@content} />
    """
  end

  component_snapshot_test "renders markdown content with complex content" do
    assigns = %{content: @with_complex_content}

    ~H"""
    <.markdown content={@content} />
    """
  end

  component_snapshot_test "renders markdown content with malicious script" do
    assigns = %{content: @with_malicious_script}

    ~H"""
    <.markdown content={@content} />
    """
  end
end
