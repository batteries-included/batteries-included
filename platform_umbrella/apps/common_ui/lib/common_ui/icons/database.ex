defmodule CommonUI.Icons.Database do
  @moduledoc false
  use CommonUI.Component

  attr :class, :any, default: nil

  def redis_icon(assigns) do
    ~H"""
    <svg
      class={build_class(["h-6 w-6 ", @class])}
      fill="currentColor"
      viewBox="0 0 1024 1024"
      version="1.1"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M941.546 458.48c-0.072 25.95-0.146 51.896-0.221 77.847-0.03 10.939-7.219 21.861-21.58 30.207l0.221-77.849c14.36-8.345 21.55-19.267 21.58-30.205zM102.488 535.902l0.221-77.848c-0.031 11.082 7.284 22.18 21.93 30.636l-0.221 77.847c-14.647-8.455-21.961-19.554-21.93-30.635z" />
      <path d="M919.966 488.686l-0.221 77.849-344.016 199.92 0.221-77.848 344.016-199.921zM470.904 688.606l-0.221 77.848-346.266-199.917 0.221-77.847a61532604.59 61532604.59 0 0 0 346.266 199.916zM575.95 688.606l-0.221 77.848c-28.915 16.803-75.942 16.803-105.046 0l0.221-77.848c29.104 16.803 76.131 16.803 105.046 0z" />
      <path d="M941.546 596.424c-0.072 25.95-0.146 51.896-0.221 77.847-0.03 10.939-7.219 21.861-21.58 30.207l0.221-77.849c14.36-8.344 21.55-19.267 21.58-30.205zM102.488 673.846l0.221-77.848c-0.031 11.081 7.284 22.18 21.93 30.635l-0.221 77.848c-14.647-8.456-21.961-19.555-21.93-30.635z" />
      <path d="M919.966 626.629l-0.221 77.849-344.016 199.92 0.221-77.848 344.016-199.921zM470.904 826.55l-0.221 77.848L124.417 704.48l0.221-77.848L470.904 826.55zM575.95 826.55l-0.221 77.848c-28.915 16.804-75.942 16.804-105.046 0l0.221-77.848c29.104 16.804 76.131 16.804 105.046 0z" />
      <path d="M940.855 361.334l-0.136 47.636c-0.001 0.2-0.004 0.4-0.01 0.6l0.136-47.637c0.006-0.2 0.009-0.4 0.01-0.599" />
      <path d="M940.846 361.933l-0.136 47.637a23.166 23.166 0 0 1-0.446 3.911l0.135-47.637c0.26-1.299 0.409-2.604 0.447-3.911M940.398 365.843l-0.135 47.637a24.923 24.923 0 0 1-1.101 3.838l0.135-47.637a24.78 24.78 0 0 0 1.101-3.838" />
      <path d="M939.298 369.682l-0.135 47.637a28.003 28.003 0 0 1-1.816 3.875l0.132-47.636a27.573 27.573 0 0 0 1.819-3.876" />
      <path d="M937.479 373.558c-0.044 15.878-0.089 31.757-0.132 47.636a32.145 32.145 0 0 1-2.744 4.074l0.136-47.637a32.134 32.134 0 0 0 2.74-4.073M934.738 377.631l-0.136 47.637a39.375 39.375 0 0 1-4.228 4.546l0.135-47.637a39.043 39.043 0 0 0 4.229-4.546" />
      <path d="M930.51 382.177l-0.135 47.637c-2.442 2.256-5.322 4.4-8.632 6.392l0.135-47.637c3.31-1.991 6.187-4.136 8.632-6.392" />
      <path d="M921.878 388.568c-0.045 15.879-0.088 31.758-0.135 47.637-0.274 0.165-0.55 0.33-0.833 0.492l0.135-47.637c0.28-0.162 0.559-0.326 0.833-0.492" />
      <path d="M122.156 389.068l-0.134 47.637c-13.444-7.762-20.158-17.949-20.128-28.121l0.134-47.636c-0.029 10.172 6.685 20.358 20.128 28.12" />
      <path d="M921.045 389.061l-0.135 47.637L570.817 640.15l0.136-47.638c116.697-67.817 233.395-135.633 350.092-203.451z" />
      <path d="M474.538 592.516l-0.135 47.639-352.381-203.449 0.134-47.637 352.382 203.447z" />
      <path d="M570.953 592.513l-0.136 47.638c-4.55 2.642-9.584 4.832-14.942 6.568l0.137-47.635c5.355-1.738 10.392-3.929 14.941-6.571M556.012 599.084l-0.137 47.635c-4.137 1.344-8.465 2.413-12.909 3.216l0.136-47.639a98.813 98.813 0 0 0 12.91-3.212" />
      <path d="M543.102 602.296l-0.136 47.639c-2.856 0.515-5.765 0.918-8.695 1.21l0.135-47.637c2.931-0.293 5.838-0.695 8.696-1.212M534.405 603.508l-0.135 47.637c-2.505 0.25-5.028 0.418-7.561 0.503l0.134-47.636a117.08 117.08 0 0 0 7.562-0.504" />
      <path d="M526.844 604.012l-0.134 47.636a117.8 117.8 0 0 1-6.983 0.034l0.134-47.637c2.327 0.056 4.659 0.047 6.983-0.033M519.86 604.045l-0.134 47.637a120.938 120.938 0 0 1-6.714-0.359l0.134-47.638c2.23 0.183 4.47 0.305 6.714 0.36" />
      <path d="M513.146 603.685l-0.134 47.638a115.989 115.989 0 0 1-6.629-0.742l0.136-47.638c2.191 0.312 4.403 0.558 6.627 0.742" />
      <path d="M506.52 602.942l-0.136 47.638a108.51 108.51 0 0 1-6.758-1.174l0.135-47.639c2.223 0.462 4.479 0.854 6.759 1.175" />
      <path d="M499.761 601.768l-0.135 47.639a101.055 101.055 0 0 1-7.11-1.744l0.134-47.636c2.324 0.661 4.698 1.241 7.111 1.741M492.65 600.026l-0.134 47.636a89.341 89.341 0 0 1-8.278-2.794l0.136-47.637a88.133 88.133 0 0 0 8.276 2.795" />
      <path d="M484.373 597.231c-0.045 15.879-0.089 31.758-0.136 47.637-3.462-1.368-6.757-2.939-9.834-4.714l0.135-47.639c3.077 1.778 6.371 3.348 9.835 4.716" />
      <path d="M920.73 333.217L568.35 129.77c-26.716-15.425-69.88-15.425-96.416-0.004L121.841 333.217c-26.54 15.424-26.399 40.426 0.314 55.851l352.383 203.448c26.709 15.422 69.874 15.421 96.415-0.003 116.697-67.817 233.396-135.634 350.092-203.452 26.534-15.421 26.393-40.424-0.315-55.844zM451.292 196.865l59.554 18.938 59.157-34.957-18.994 49.333 56.245 22.514-71.293 11.543-24.391 48.874-25.065-42.198-71.32 7.696 55.797-37.632-19.69-44.111z m-174.269 172.75c-12.726-7.347-21.302-17.198-23.209-28.349-4.357-25.492 27.777-48.135 71.771-50.577 24.75-1.374 47.977 3.938 64.342 13.387 12.726 7.348 21.303 17.199 23.208 28.35 4.358 25.491-27.771 48.138-71.77 50.576-24.75 1.374-47.975-3.938-64.342-13.387z m255.765 163.789l-155.58-89.825 211.652-32.876-56.072 122.701zM688.366 428.68l-128.454-74.163 127.617-74.166 128.456 74.165-127.619 74.164z" />
      <path d="M941.546 458.48c-0.072 25.95-0.146 51.896-0.221 77.847-0.03 10.939-7.219 21.861-21.58 30.207l0.221-77.849c14.36-8.345 21.55-19.267 21.58-30.205zM102.488 535.902l0.221-77.848c-0.031 11.082 7.284 22.18 21.93 30.636l-0.221 77.847c-14.647-8.455-21.961-19.554-21.93-30.635z" />
      <path d="M919.966 488.686l-0.221 77.849-344.016 199.92 0.221-77.848 344.016-199.921zM470.904 688.606l-0.221 77.848-346.266-199.917 0.221-77.847a61532604.59 61532604.59 0 0 0 346.266 199.916zM575.95 688.606l-0.221 77.848c-28.915 16.803-75.942 16.803-105.046 0l0.221-77.848c29.104 16.803 76.131 16.803 105.046 0z" />
      <path d="M941.546 596.424c-0.072 25.95-0.146 51.896-0.221 77.847-0.03 10.939-7.219 21.861-21.58 30.207l0.221-77.849c14.36-8.344 21.55-19.267 21.58-30.205zM102.488 673.846l0.221-77.848c-0.031 11.081 7.284 22.18 21.93 30.635l-0.221 77.848c-14.647-8.456-21.961-19.555-21.93-30.635z" />
      <path d="M919.966 626.629l-0.221 77.849-344.016 199.92 0.221-77.848 344.016-199.921zM470.904 826.55l-0.221 77.848L124.417 704.48l0.221-77.848L470.904 826.55zM575.95 826.55l-0.221 77.848c-28.915 16.804-75.942 16.804-105.046 0l0.221-77.848c29.104 16.804 76.131 16.804 105.046 0z" />
      <path d="M940.855 361.334l-0.136 47.636c-0.001 0.2-0.004 0.4-0.01 0.6l0.136-47.637c0.006-0.2 0.009-0.4 0.01-0.599" />
      <path d="M940.846 361.933l-0.136 47.637a23.166 23.166 0 0 1-0.446 3.911l0.135-47.637c0.26-1.299 0.409-2.604 0.447-3.911M940.398 365.843l-0.135 47.637a24.923 24.923 0 0 1-1.101 3.838l0.135-47.637a24.78 24.78 0 0 0 1.101-3.838" />
      <path d="M939.298 369.682l-0.135 47.637a28.003 28.003 0 0 1-1.816 3.875l0.132-47.636a27.573 27.573 0 0 0 1.819-3.876" />
      <path d="M937.479 373.558c-0.044 15.878-0.089 31.757-0.132 47.636a32.145 32.145 0 0 1-2.744 4.074l0.136-47.637a32.134 32.134 0 0 0 2.74-4.073M934.738 377.631l-0.136 47.637a39.375 39.375 0 0 1-4.228 4.546l0.135-47.637a39.043 39.043 0 0 0 4.229-4.546" />
      <path d="M930.51 382.177l-0.135 47.637c-2.442 2.256-5.322 4.4-8.632 6.392l0.135-47.637c3.31-1.991 6.187-4.136 8.632-6.392" />
      <path d="M921.878 388.568c-0.045 15.879-0.088 31.758-0.135 47.637-0.274 0.165-0.55 0.33-0.833 0.492l0.135-47.637c0.28-0.162 0.559-0.326 0.833-0.492" />
      <path d="M122.156 389.068l-0.134 47.637c-13.444-7.762-20.158-17.949-20.128-28.121l0.134-47.636c-0.029 10.172 6.685 20.358 20.128 28.12" />
      <path d="M921.045 389.061l-0.135 47.637L570.817 640.15l0.136-47.638c116.697-67.817 233.395-135.633 350.092-203.451z" />
      <path d="M474.538 592.516l-0.135 47.639-352.381-203.449 0.134-47.637 352.382 203.447z" />
      <path d="M570.953 592.513l-0.136 47.638c-4.55 2.642-9.584 4.832-14.942 6.568l0.137-47.635c5.355-1.738 10.392-3.929 14.941-6.571M556.012 599.084l-0.137 47.635c-4.137 1.344-8.465 2.413-12.909 3.216l0.136-47.639a98.813 98.813 0 0 0 12.91-3.212" />
      <path d="M543.102 602.296l-0.136 47.639c-2.856 0.515-5.765 0.918-8.695 1.21l0.135-47.637c2.931-0.293 5.838-0.695 8.696-1.212M534.405 603.508l-0.135 47.637c-2.505 0.25-5.028 0.418-7.561 0.503l0.134-47.636a117.08 117.08 0 0 0 7.562-0.504" />
      <path d="M526.844 604.012l-0.134 47.636a117.8 117.8 0 0 1-6.983 0.034l0.134-47.637c2.327 0.056 4.659 0.047 6.983-0.033M519.86 604.045l-0.134 47.637a120.938 120.938 0 0 1-6.714-0.359l0.134-47.638c2.23 0.183 4.47 0.305 6.714 0.36" />
      <path d="M513.146 603.685l-0.134 47.638a115.989 115.989 0 0 1-6.629-0.742l0.136-47.638c2.191 0.312 4.403 0.558 6.627 0.742" />
      <path d="M506.52 602.942l-0.136 47.638a108.51 108.51 0 0 1-6.758-1.174l0.135-47.639c2.223 0.462 4.479 0.854 6.759 1.175" />
      <path d="M499.761 601.768l-0.135 47.639a101.055 101.055 0 0 1-7.11-1.744l0.134-47.636c2.324 0.661 4.698 1.241 7.111 1.741M492.65 600.026l-0.134 47.636a89.341 89.341 0 0 1-8.278-2.794l0.136-47.637a88.133 88.133 0 0 0 8.276 2.795" />
      <path d="M484.373 597.231c-0.045 15.879-0.089 31.758-0.136 47.637-3.462-1.368-6.757-2.939-9.834-4.714l0.135-47.639c3.077 1.778 6.371 3.348 9.835 4.716" />
      <path d="M920.73 333.217L568.35 129.77c-26.716-15.425-69.88-15.425-96.416-0.004L121.841 333.217c-26.54 15.424-26.399 40.426 0.314 55.851l352.383 203.448c26.709 15.422 69.874 15.421 96.415-0.003 116.697-67.817 233.396-135.634 350.092-203.452 26.534-15.421 26.393-40.424-0.315-55.844zM451.292 196.865l59.554 18.938 59.157-34.957-18.994 49.333 56.245 22.514-71.293 11.543-24.391 48.874-25.065-42.198-71.32 7.696 55.797-37.632-19.69-44.111z m-174.269 172.75c-12.726-7.347-21.302-17.198-23.209-28.349-4.357-25.492 27.777-48.135 71.771-50.577 24.75-1.374 47.977 3.938 64.342 13.387 12.726 7.348 21.303 17.199 23.208 28.35 4.358 25.491-27.771 48.138-71.77 50.576-24.75 1.374-47.975-3.938-64.342-13.387z m255.765 163.789l-155.58-89.825 211.652-32.876-56.072 122.701zM688.366 428.68l-128.454-74.163 127.617-74.166 128.456 74.165-127.619 74.164z" />
      <path d="M941.546 458.48c-0.072 25.95-0.146 51.896-0.221 77.847-0.03 10.939-7.219 21.861-21.58 30.207l0.221-77.849c14.36-8.345 21.55-19.267 21.58-30.205zM102.488 535.902l0.221-77.848c-0.031 11.082 7.284 22.18 21.93 30.636l-0.221 77.847c-14.647-8.455-21.961-19.554-21.93-30.635z" />
      <path d="M919.966 488.686l-0.221 77.849-344.016 199.92 0.221-77.848 344.016-199.921zM470.904 688.606l-0.221 77.848-346.266-199.917 0.221-77.847a61532604.59 61532604.59 0 0 0 346.266 199.916zM575.95 688.606l-0.221 77.848c-28.915 16.803-75.942 16.803-105.046 0l0.221-77.848c29.104 16.803 76.131 16.803 105.046 0z" />
      <path d="M941.546 596.424c-0.072 25.95-0.146 51.896-0.221 77.847-0.03 10.939-7.219 21.861-21.58 30.207l0.221-77.849c14.36-8.344 21.55-19.267 21.58-30.205zM102.488 673.846l0.221-77.848c-0.031 11.081 7.284 22.18 21.93 30.635l-0.221 77.848c-14.647-8.456-21.961-19.555-21.93-30.635z" />
      <path d="M919.966 626.629l-0.221 77.849-344.016 199.92 0.221-77.848 344.016-199.921zM470.904 826.55l-0.221 77.848L124.417 704.48l0.221-77.848L470.904 826.55zM575.95 826.55l-0.221 77.848c-28.915 16.804-75.942 16.804-105.046 0l0.221-77.848c29.104 16.804 76.131 16.804 105.046 0z" />
      <path d="M940.855 361.334l-0.136 47.636c-0.001 0.2-0.004 0.4-0.01 0.6l0.136-47.637c0.006-0.2 0.009-0.4 0.01-0.599" />
      <path d="M940.846 361.933l-0.136 47.637a23.166 23.166 0 0 1-0.446 3.911l0.135-47.637c0.26-1.299 0.409-2.604 0.447-3.911M940.398 365.843l-0.135 47.637a24.923 24.923 0 0 1-1.101 3.838l0.135-47.637a24.78 24.78 0 0 0 1.101-3.838" />
      <path d="M939.298 369.682l-0.135 47.637a28.003 28.003 0 0 1-1.816 3.875l0.132-47.636a27.573 27.573 0 0 0 1.819-3.876" />
      <path d="M937.479 373.558c-0.044 15.878-0.089 31.757-0.132 47.636a32.145 32.145 0 0 1-2.744 4.074l0.136-47.637a32.134 32.134 0 0 0 2.74-4.073M934.738 377.631l-0.136 47.637a39.375 39.375 0 0 1-4.228 4.546l0.135-47.637a39.043 39.043 0 0 0 4.229-4.546" />
      <path d="M930.51 382.177l-0.135 47.637c-2.442 2.256-5.322 4.4-8.632 6.392l0.135-47.637c3.31-1.991 6.187-4.136 8.632-6.392" />
      <path d="M921.878 388.568c-0.045 15.879-0.088 31.758-0.135 47.637-0.274 0.165-0.55 0.33-0.833 0.492l0.135-47.637c0.28-0.162 0.559-0.326 0.833-0.492" />
      <path d="M122.156 389.068l-0.134 47.637c-13.444-7.762-20.158-17.949-20.128-28.121l0.134-47.636c-0.029 10.172 6.685 20.358 20.128 28.12" />
      <path d="M921.045 389.061l-0.135 47.637L570.817 640.15l0.136-47.638c116.697-67.817 233.395-135.633 350.092-203.451z" />
      <path d="M474.538 592.516l-0.135 47.639-352.381-203.449 0.134-47.637 352.382 203.447z" />
      <path d="M570.953 592.513l-0.136 47.638c-4.55 2.642-9.584 4.832-14.942 6.568l0.137-47.635c5.355-1.738 10.392-3.929 14.941-6.571M556.012 599.084l-0.137 47.635c-4.137 1.344-8.465 2.413-12.909 3.216l0.136-47.639a98.813 98.813 0 0 0 12.91-3.212" />
      <path d="M543.102 602.296l-0.136 47.639c-2.856 0.515-5.765 0.918-8.695 1.21l0.135-47.637c2.931-0.293 5.838-0.695 8.696-1.212M534.405 603.508l-0.135 47.637c-2.505 0.25-5.028 0.418-7.561 0.503l0.134-47.636a117.08 117.08 0 0 0 7.562-0.504" />
      <path d="M526.844 604.012l-0.134 47.636a117.8 117.8 0 0 1-6.983 0.034l0.134-47.637c2.327 0.056 4.659 0.047 6.983-0.033M519.86 604.045l-0.134 47.637a120.938 120.938 0 0 1-6.714-0.359l0.134-47.638c2.23 0.183 4.47 0.305 6.714 0.36" />
      <path d="M513.146 603.685l-0.134 47.638a115.989 115.989 0 0 1-6.629-0.742l0.136-47.638c2.191 0.312 4.403 0.558 6.627 0.742" />
      <path d="M506.52 602.942l-0.136 47.638a108.51 108.51 0 0 1-6.758-1.174l0.135-47.639c2.223 0.462 4.479 0.854 6.759 1.175" />
      <path d="M499.761 601.768l-0.135 47.639a101.055 101.055 0 0 1-7.11-1.744l0.134-47.636c2.324 0.661 4.698 1.241 7.111 1.741M492.65 600.026l-0.134 47.636a89.341 89.341 0 0 1-8.278-2.794l0.136-47.637a88.133 88.133 0 0 0 8.276 2.795" />
      <path d="M484.373 597.231c-0.045 15.879-0.089 31.758-0.136 47.637-3.462-1.368-6.757-2.939-9.834-4.714l0.135-47.639c3.077 1.778 6.371 3.348 9.835 4.716" />
      <path d="M920.73 333.217L568.35 129.77c-26.716-15.425-69.88-15.425-96.416-0.004L121.841 333.217c-26.54 15.424-26.399 40.426 0.314 55.851l352.383 203.448c26.709 15.422 69.874 15.421 96.415-0.003 116.697-67.817 233.396-135.634 350.092-203.452 26.534-15.421 26.393-40.424-0.315-55.844zM451.292 196.865l59.554 18.938 59.157-34.957-18.994 49.333 56.245 22.514-71.293 11.543-24.391 48.874-25.065-42.198-71.32 7.696 55.797-37.632-19.69-44.111z m-174.269 172.75c-12.726-7.347-21.302-17.198-23.209-28.349-4.357-25.492 27.777-48.135 71.771-50.577 24.75-1.374 47.977 3.938 64.342 13.387 12.726 7.348 21.303 17.199 23.208 28.35 4.358 25.491-27.771 48.138-71.77 50.576-24.75 1.374-47.975-3.938-64.342-13.387z m255.765 163.789l-155.58-89.825 211.652-32.876-56.072 122.701zM688.366 428.68l-128.454-74.163 127.617-74.166 128.456 74.165-127.619 74.164z" />
    </svg>
    """
  end

  attr :class, :any, default: nil

  def database_icon(assigns) do
    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="-0.48 -0.48 24.89 24.89" class={@class}>
      <path d="M12 6C10.772 6 0 5.916 0 3s10.772-3 12-3 12 .084 12 3-10.772 3-12 3zM1.588 3C2.32 3.568 5.833 4.5 12 4.5s9.68-.932 10.412-1.5C21.68 2.432 18.167 1.5 12 1.5S2.32 2.432 1.588 3zm20.939.116h.01zM12 12c-1.228 0-12-.084-12-3 0-.414.336-.75.75-.75.385 0 .702.29.745.664C1.957 9.467 5.507 10.5 12 10.5s10.043-1.033 10.505-1.586c.043-.374.36-.664.745-.664.414 0 .75.336.75.75 0 2.916-10.772 3-12 3zm10.5-3.001c0 .001 0 .001 0 0zm-21 0c0 .001 0 .001 0 0zM12 18c-1.228 0-12-.084-12-3 0-.414.336-.75.75-.75.385 0 .702.29.745.664C1.957 15.467 5.507 16.5 12 16.5s10.043-1.033 10.505-1.586c.043-.374.36-.664.745-.664.414 0 .75.336.75.75 0 2.916-10.772 3-12 3zm10.5-3.001c0 .001 0 .001 0 0zm-21 0c0 .001 0 .001 0 0z" /><path d="M12 24c-1.228 0-12-.084-12-3V3c0-.414.336-.75.75-.75s.75.336.75.75v17.919c.481.556 4.03 1.581 10.5 1.581s10.019-1.025 10.5-1.581V3c0-.414.336-.75.75-.75s.75.336.75.75v18c0 2.916-10.772 3-12 3z" />
      <circle cx="5" cy="14" r="1" />
      <circle cx="5" cy="8" r="1" />
      <circle cx="5" cy="20" r="1" />
    </svg>
    """
  end
end
