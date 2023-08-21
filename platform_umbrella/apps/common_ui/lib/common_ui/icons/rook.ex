defmodule CommonUI.Icons.Rook do
  @moduledoc false
  use CommonUI.Component

  def ceph_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      class={build_class(["h-6 w-6 ", @class])}
      viewBox="-3.22 -4.4 66.773 66.338"
      fill="currentColor"
    >
      <path d="M51.727 55.793c-2.427-1.3-3.813-2.746-4.12-4.326-.296-1.53.387-3.232 2.088-5.204 4.067-4.666 6.307-10.66 6.307-16.88C56.002 15.2 44.462 3.66 30.28 3.66h-.23C15.866 3.66 4.33 15.2 4.33 29.383a25.68 25.68 0 0 0 6.308 16.881c1.715 1.985 2.38 3.618 2.096 5.134-.295 1.578-1.684 3.054-4.132 4.392-3.754-3.13-7.073-7.308-9.12-11.5-1.1-2.275-1.965-4.678-2.542-7.14-.593-2.532-.9-5.145-.9-7.765a33.82 33.82 0 0 1 2.67-13.237A33.89 33.89 0 0 1 6.008 5.341a33.85 33.85 0 0 1 10.806-7.286C21.008-3.72 25.46-4.618 30.05-4.618h.23a33.78 33.78 0 0 1 13.238 2.673C47.566-.232 51.203 2.22 54.324 5.34a33.91 33.91 0 0 1 7.287 10.806 33.81 33.81 0 0 1 2.673 13.237 34.18 34.18 0 0 1-.892 7.765c-.576 2.463-1.43 4.866-2.543 7.14-2.047 4.194-5.364 8.373-9.123 11.503M39.18 62.155c-.395-.25-1.745-1.253-3.06-3.076-1.262-1.742-2.748-4.632-2.67-8.502.05-2.33.516-4.597 1.4-6.74.87-2.123 2.114-4.068 3.7-5.78l.01-.013.35-.405c.6-.695 1.218-1.412 1.712-2.252a11.66 11.66 0 0 0 1.315-3.226 12.14 12.14 0 0 0 .066-5.257c-.335-1.586-1-3.123-1.95-4.448-.912-1.284-2.1-2.404-3.438-3.238a12 12 0 0 0-4.626-1.685 11.83 11.83 0 0 0-1.693-.12h-.244a11.93 11.93 0 0 0-1.691.12 11.99 11.99 0 0 0-4.626 1.685c-1.337.834-2.528 1.954-3.44 3.238a12.08 12.08 0 0 0-1.95 4.448 12.11 12.11 0 0 0 .068 5.257c.262 1.1.706 2.194 1.313 3.226.496.84 1.114 1.557 1.713 2.252l.352.405.007.013a19.1 19.1 0 0 1 3.703 5.78c.875 2.14 1.343 4.4 1.4 6.74.08 3.87-1.407 6.76-2.668 8.502-1.32 1.823-2.667 2.827-3.063 3.076l-1.97-.593a33.91 33.91 0 0 1-5.665-2.497 9.67 9.67 0 0 0 5.084-8.496c0-2.355-.915-4.613-2.72-6.7-.027-.032-.055-.058-.075-.08l-.54-.592-1.448-1.696a20.3 20.3 0 0 1-3.469-7.414 20.43 20.43 0 0 1-.112-8.882 20.37 20.37 0 0 1 3.301-7.537 20.47 20.47 0 0 1 5.807-5.469c2.366-1.476 5.078-2.463 7.84-2.856a20.09 20.09 0 0 1 2.853-.2h.256a20.1 20.1 0 0 1 2.854.2 20.35 20.35 0 0 1 7.841 2.856c2.258 1.408 4.267 3.3 5.808 5.47 1.592 2.243 2.735 4.85 3.303 7.537a20.5 20.5 0 0 1-.113 8.882 20.3 20.3 0 0 1-3.472 7.414c-.44.6-.93 1.127-1.45 1.696l-.523.577c-.006.005-.01.01-.016.014-.02.02-.05.048-.075.083-1.83 2.2-2.72 4.383-2.72 6.706 0 3.558 1.976 6.823 5.088 8.496a33.95 33.95 0 0 1-5.666 2.497l-1.973.593M30.165 36.42c-3.7 0-6.713-3.012-6.713-6.713s3.012-6.714 6.713-6.714 6.712 3.012 6.712 6.714a6.72 6.72 0 0 1-6.712 6.713" />
    </svg>
    """
  end
end
