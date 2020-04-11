defmodule YookerWeb.GameLive do
  use Phoenix.LiveView
  alias Yooker.State
  require Logger

  def render(assigns) do
    YookerWeb.GameView.render("index.html", assigns)
  end

  def handle_params(%{"name" => name} = _params, _url, socket) do
    :ok = Phoenix.PubSub.subscribe(Yooker.PubSub, name)
    {:noreply, assign_game(socket, name)}
  end

  def handle_params(_params, _uri, socket) do
		name =
      ?a..?z
      |> Enum.take_random(6)
      |> List.to_string()

    # Flying a little blind on logic for push_patch, etc -- need to understand this better
    # TODO
    {:ok, _pid} =
      DynamicSupervisor.start_child(Yooker.GameSupervisor, {State, name: via_tuple(name)})

    # Push patch or push redirect? do I want to update the same liveview or mount another..?
    {:noreply, push_patch(
      socket,
      to: YookerWeb.Router.Helpers.live_path(socket, YookerWeb.GameLive, name: name)
    )}
  end

	defp via_tuple(name) do
    {:via, Registry, {Yooker.GameRegistry, name}}
  end

  defp assign_game(socket, name) do
    socket
    |> assign(name: name)
    |> assign_game()
  end

  defp assign_game(%{assigns: %{name: name}} = socket) do
    state = GenServer.call(via_tuple(name), :state)
    # TODO(bmchrist) figure out why we need to manually define the default layout)
    assign(socket, layout: {YookerWeb.LayoutView, "app.html"}, state: state)
  end

  def handle_event("deal", _event, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:deal})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("choose-trump", %{"suit" => suit}, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:choose_trump, suit})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("pass-trump", _event, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:pass_trump})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("play-card", %{"card" => card}, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:play_card, card})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end
end
