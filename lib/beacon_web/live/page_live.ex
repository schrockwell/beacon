defmodule BeaconWeb.PageLive do
  use BeaconWeb, :live_view_dynamic

  require Logger

  def mount(%{"path" => path} = params, %{"beacon_site" => site}, socket) do
    live_data = Beacon.DataSource.live_data(site, path, Map.drop(params, ["path"]))

    dynamic_layout_data =
      site
      |> Beacon.Loader.page_module_for_site()
      |> Beacon.Loader.call_function_with_retry(:dynamic_layout_data, [path])

    socket =
      socket
      |> assign(:beacon_live_data, live_data)
      |> assign(:__live_path__, path)
      |> assign(:__page_update_available__, false)
      |> assign(:__dynamic_layout_data__, dynamic_layout_data)
      |> assign(:__site__, site)

    socket =
      socket
      |> push_event("meta", %{meta: BeaconWeb.LayoutView.meta_tags_unsafe(socket.assigns, dynamic_layout_data)})
      |> push_event("lang", %{lang: "en"})

    Beacon.PubSub.subscribe_page_update(site, path)

    {:ok, socket}
  end

  def render(assigns) do
    {%{__live_path__: live_path}, render_assigns} = Map.split(assigns, [:__live_path__])

    module = Beacon.Loader.page_module_for_site(assigns.__site__)

    Beacon.Loader.call_function_with_retry(module, :render, [live_path, render_assigns])
  end

  def handle_info(:page_updated, socket) do
    {:noreply, assign(socket, :__page_update_available__, true)}
  end
end
