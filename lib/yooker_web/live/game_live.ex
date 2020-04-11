defmodule YookerWeb.GameLive do
  use Phoenix.LiveView
  alias Yooker.State
  require Logger

  def render(assigns) do
    YookerWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, _params, socket) do # most guides don't list needing /3 (params) but does nto get called otherwise - look into this
		name =
      ?a..?z
      |> Enum.take_random(6)
      |> List.to_string()

    {:ok, _pid} =
      DynamicSupervisor.start_child(Yooker.GameSupervisor, {State, name: via_tuple(name)})

    {:ok, assign_game(socket, name)}
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
    {:noreply, assign_game(socket)}
  end

  def handle_event("choose-trump", %{"suit" => suit}, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:choose_trump, suit})
    {:noreply, assign_game(socket)}
  end

  def handle_event("pass-trump", _event, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:pass_trump})
    {:noreply, assign_game(socket)}
  end

  def handle_event("play-card", %{"card" => card}, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:play_card, card})
    {:noreply, assign_game(socket)}
  end
end
