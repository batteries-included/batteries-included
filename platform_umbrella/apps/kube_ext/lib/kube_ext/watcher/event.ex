defmodule KubeExt.Watcher.Event do
  @moduledoc false
  use KubeExt.Telemetry, name: :kube_ext_watcher

  defevent([:watcher, :initialized])
  defevent([:watcher, :first_resource, :started])
  defevent([:watcher, :first_resource, :finished])
  defevent([:watcher, :first_resource, :succeeded])
  defevent([:watcher, :first_resource, :failed])
  defevent([:watcher, :watch, :started])
  defevent([:watcher, :watch, :succeeded])
  defevent([:watcher, :watch, :finished])
  defevent([:watcher, :watch, :down])
  defevent([:watcher, :watch, :failed])
  defevent([:watcher, :watch, :timedout])
  defevent([:watcher, :fetch, :failed])
  defevent([:watcher, :fetch, :succeeded])
  defevent([:watcher, :chunk, :received])
  defevent([:watcher, :chunk, :finished])
  defevent([:watcher, :genserver, :down])
end
