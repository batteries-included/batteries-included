defmodule CommonUI.Icons.Network do
  @moduledoc false
  use CommonUI.Component

  attr :class, :any, default: nil

  def kiali_icon(assigns) do
    ~H"""
    <svg
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      viewBox="0 0 1280 1280"
      style="enable-background:new 0 0 1280 1280;"
      class={build_class(["h-6 w-6 ", @class])}
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

  attr :class, :any, default: nil

  def net_sec_icon(assigns) do
    ~H"""
    <svg
      id="Layer_1"
      data-name="Layer 1"
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 122.88 114.3"
      stroke="currentColor"
      fill="currentColor"
      class={build_class(["h-6 w-6 ", @class])}
    >
      <defs>
        <style>
          .cls-1{fill-rule:evenodd;}
        </style>
      </defs>

      <path
        class="cls-1"
        d="M61.46,24.21c11.15,7.07,21.23,10.42,29.87,9.62C92.84,64.38,81.56,82.42,61.57,90c-19.3-7-30.72-24.31-29.87-56.58,10.15.53,20.11-1.66,29.76-9.16Zm14.14-5.3v4.38c1.16.5,2.31.95,3.45,1.37v-4h4a5.06,5.06,0,1,0,0-3.45H77.32a1.71,1.71,0,0,0-1.72,1.72ZM0,36.48a5.06,5.06,0,1,1,7.09,4.63V51.22H25.43c.2,1.17.41,2.32.64,3.45H5.37A1.71,1.71,0,0,1,3.65,53V41.34A5.05,5.05,0,0,1,0,36.48Zm13.91-3.36a5.05,5.05,0,0,1,10-.94c0,.59,0,1.18,0,1.77a5.1,5.1,0,0,1-3.31,3.94v4h3.67c.09,1.17.2,2.32.32,3.45H18.91a1.72,1.72,0,0,1-1.72-1.72V37.85a5,5,0,0,1-3.28-4.73ZM.08,64.49a5.06,5.06,0,0,1,9.81-1.73H28.16c.37,1.18.77,2.33,1.18,3.45H9.89A5.06,5.06,0,0,1,.08,64.49ZM11,85.54a5.06,5.06,0,0,1,3.26-4.73V74.16A1.72,1.72,0,0,1,16,72.44H32.05c.59,1.19,1.22,2.34,1.88,3.46H17.71v4.86A5.06,5.06,0,1,1,11,85.54ZM84.4,114.3a5.06,5.06,0,1,0-4.62-7.1H69.67V94.72q-1.68.93-3.45,1.77v12.44a1.72,1.72,0,0,0,1.72,1.72H79.55a5.05,5.05,0,0,0,4.85,3.65Zm3.37-13.91A5.06,5.06,0,1,0,83,93.66h-4V88.18q-1.67,1.45-3.45,2.76v4.45a1.71,1.71,0,0,0,1.72,1.72H83a5,5,0,0,0,4.73,3.28ZM56.4,114.21a5.05,5.05,0,0,0,1.73-9.8V97.07C57,96.56,55.8,96,54.68,95.43v9a5.05,5.05,0,0,0,1.72,9.8Zm-21-10.91A5.06,5.06,0,0,0,40.08,100h6.65a1.74,1.74,0,0,0,1.72-1.73V91.68C47.26,90.85,46.11,90,45,89v7.56H40.13a5.06,5.06,0,1,0-4.78,6.71Zm87.53-66.82a5.06,5.06,0,1,0-7.09,4.63V51.22H98c-.18,1.17-.39,2.32-.62,3.45h20.18A1.71,1.71,0,0,0,119.23,53V41.34a5.05,5.05,0,0,0,3.65-4.86ZM109,33.12a5.05,5.05,0,0,0-9.81-1.71,5.69,5.69,0,0,0,0,3.51,5.1,5.1,0,0,0,3,3v4H99c-.08,1.17-.17,2.32-.28,3.45H104a1.72,1.72,0,0,0,1.72-1.72V37.85A5,5,0,0,0,109,33.12ZM122.8,64.49A5.06,5.06,0,0,0,113,62.76H95.25c-.38,1.18-.78,2.33-1.21,3.45H113a5.06,5.06,0,0,0,9.81-1.72ZM111.88,85.54a5.06,5.06,0,0,0-3.26-4.73V74.16a1.72,1.72,0,0,0-1.73-1.72H91.28c-.61,1.19-1.26,2.34-1.93,3.46h15.82v4.86a5.06,5.06,0,1,0,6.71,4.78ZM84.4,0a5.06,5.06,0,1,1-4.62,7.09H69.67V20.48c-1.14-.6-2.29-1.22-3.45-1.88V5.37a1.71,1.71,0,0,1,1.72-1.72H79.55A5.05,5.05,0,0,1,84.4,0ZM56.4.08a5.06,5.06,0,0,1,1.73,9.81v8.22q-1.73,1.17-3.45,2.16V9.89A5.06,5.06,0,0,1,56.4.08ZM35.35,11a5.06,5.06,0,0,1,4.73,3.26h6.65A1.74,1.74,0,0,1,48.45,16v7.35c-1.15.48-2.3.91-3.46,1.29V17.71H40.13A5.06,5.06,0,1,1,35.35,11Zm15,39.13h1.11V48.08a10.61,10.61,0,0,1,2.94-7.35,9.77,9.77,0,0,1,14.28,0,10.61,10.61,0,0,1,2.94,7.35v2.05h1.11a1.66,1.66,0,0,1,1.65,1.65V69.16a1.65,1.65,0,0,1-1.65,1.64H50.37a1.65,1.65,0,0,1-1.65-1.64V51.78a1.66,1.66,0,0,1,1.65-1.65Zm9.84,11.1-1.77,4.65h6.24L63,61.17a3.24,3.24,0,1,0-2.83.06ZM54.6,50.13H68.52V48.08a7.51,7.51,0,0,0-2.06-5.2,6.7,6.7,0,0,0-9.8,0,7.51,7.51,0,0,0-2.06,5.2v2.05Z"
      />
    </svg>
    """
  end
end
