defmodule CommonUI.Icons.Network do
  use Phoenix.Component

  def kiali_icon(assigns) do
    ~H"""
    <svg
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      viewBox="0 0 1280 1280"
      style="enable-background:new 0 0 1280 1280;"
      class={"h-6 w-6 " <> @class}
      stroke="currentColor"
      fill="currentColor"
      xml:space="preserve"
    >
      <style type="text/css">
        .st0{fill:#013144;}
        .st1{fill:#0093DD;}
      </style>
      <g>
        <path d="M810.9,180.9c-253.6,0-459.1,205.5-459.1,459.1s205.5,459.1,459.1,459.1S1270,893.6,1270,640
    		S1064.5,180.9,810.9,180.9z M810.9,1029.2c-215,0-389.2-174.3-389.2-389.2c0-215,174.3-389.2,389.2-389.2S1200.1,425,1200.1,640
    		S1025.9,1029.2,810.9,1029.2z" />
        <path d="M653.3,284c-136.4,60.5-231.6,197.1-231.6,356c0,158.8,95.2,295.5,231.6,356c98.4-87.1,160.4-214.3,160.4-356
    		C813.7,498.3,751.6,371.1,653.3,284z" />
        <path d="M351.8,640c0-109.8,38.6-210.5,102.8-289.5c-39.6-18.2-83.6-28.3-130-28.3C150.9,322.2,10,464.5,10,640
    		s140.9,317.8,314.6,317.8c46.3,0,90.4-10.1,130-28.3C390.3,850.5,351.8,749.8,351.8,640z" />
      </g>
    </svg>
    """
  end
end
