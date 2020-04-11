defmodule YookerWeb.GameLive do
  use Phoenix.LiveView
  alias Yooker.Game
  require Logger

  def render(assigns) do
    YookerWeb.GameView.render("index.html", assigns)
  end

  # TODO decide whether to use handle_params or the router.. likely switch to using router if we have a game selecting lobby..

  # Joining an existing game, as an existing player
  def handle_params(%{"game" => game_name, "player" => player} = _params, _url, socket) do
    :ok = Phoenix.PubSub.subscribe(Yooker.PubSub, game_name)
    {:noreply, assign_game(socket, game_name, player)}
  end

  # Joining an existing game, but no assigned player yet - generate player_id and update params
  def handle_params(%{"game" => game_name} = _params, _url, socket) do
    player = generate_name()

    # We push patch since we're using this same live view, just updating params
    {:noreply, push_patch(
      socket,
      to: YookerWeb.Router.Helpers.live_path(socket, YookerWeb.GameLive, game: game_name, player: player)
    )}
  end

  # No game - create a new one and assign the player
  def handle_params(_params, _uri, socket) do
		game_name = generate_name()

    {:ok, _pid} =
      DynamicSupervisor.start_child(Yooker.GameSupervisor, {Game, name: via_tuple(game_name)})

    # We push patch since we're using this same live view, just updating params
    # We could get rid of one redirect if we also assigned a player id here - but for now this is cleaner logic to deal with
    # Update params, which will trigger handle_params for game being present but no player
    {:noreply, push_patch(
      socket,
      to: YookerWeb.Router.Helpers.live_path(socket, YookerWeb.GameLive, game: game_name)
    )}
  end

  defp generate_name() do
    # TODO - no game name collision handling...
    ?a..?z
      |> Enum.take_random(6)
      |> List.to_string()
  end

	defp via_tuple(name) do
    {:via, Registry, {Yooker.GameRegistry, name}}
  end

  # This runs when someone first loads a page - either with params for a game or no params
  defp assign_game(socket, name, pid) do
    socket
    |> assign(name: name, pid: pid)
    |> assign_game()
  end

  # TODO - this runs twice for every action taken in the browser - figure out why and if that's needed.
  defp assign_game(%{assigns: %{name: name, pid: pid}} = socket) do
    game = %Game{state: state} = GenServer.call(via_tuple(name), :game)
    # TODO(bmchrist) figure out why we need to manually define the default layout)
    # TODO - not needed to pass state and game in -- redundant, since game has state - fix later
    # TODO learn more about assign - do I actually need to assign pid every time.. or is that to only make accessible to the view
    assign(socket, layout: {YookerWeb.LayoutView, "app.html"}, pid: pid, game: game, state: state)
  end

  ##################################
  # Handle game actions from players
  ##################################
  def handle_event("claim-seat", %{"seat" => seat}, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:claim_seat, seat, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("deal", _event, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:deal, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("choose-trump", %{"suit" => suit}, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:choose_trump, suit, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("pass-trump", _event, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:pass_trump, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("play-card", %{"card" => card}, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:play_card, card, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_info(:update, socket) do
    {:noreply, assign_game(socket)}
  end
end
