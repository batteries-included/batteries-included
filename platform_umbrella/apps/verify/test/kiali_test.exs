defmodule Verify.KialiTest do
  use Verify.TestCase,
    async: false,
    batteries: ~w(kiali)a,
    images: ~w(grafana kiali vm_operator vm_insert vm_select vm_storage vm_agent)a

  verify "kiali is running", %{session: session} do
    session
    |> assert_pod_running("kiali-")
    |> visit("/net_sec")
    |> click_external(Query.css("a", text: "Kiali"))
    # find the link to the website in the footer
    |> assert_has(Query.css(~s|header img[alt="Kiali Logo"]|))
  end
end
