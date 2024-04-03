defmodule CommonUI.Components.VideoTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Video

  component_snapshot_test "default video" do
    assigns = %{}

    ~H"""
    <.video
      src="https://www.youtube.com/embed/dQw4w9WgXcQ?si=UZCUB2JKWZe3_5Uw"
      allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
      referrerpolicy="strict-origin-when-cross-origin"
      allowfullscreen
    />
    """
  end
end
