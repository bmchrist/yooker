defmodule YookerWeb.GameLive do
  use Phoenix.LiveView
  alias Yooker.Game
  require Logger

  def render(assigns) do
    YookerWeb.GameView.render("index.html", assigns)
  end

  # Joining an existing game
  def handle_params(%{"game" => game_name, "player" => player} = _params, _url, socket) do
    if length(Registry.lookup(Yooker.GameRegistry, game_name)) > 0 do
      :ok = Phoenix.PubSub.subscribe(Yooker.PubSub, "game-" <> game_name)
      {:noreply, assign_game(socket, game_name, player)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Could Not Find Game")
       |> push_redirect(to: YookerWeb.Router.Helpers.live_path(socket, YookerWeb.LobbyLive))}
    end
  end

  # Player creating a new game
  def handle_params(%{"player" => player} = _params, _url, socket) do
    game_name = generate_name()

    # If this ends up generating a name that's already in use, it will fail. Could use Registry.lookup
    # and loop until it doesn't find a match, but complication isn't worth it at this time

    {:ok, _pid} =
      DynamicSupervisor.start_child(Yooker.GameSupervisor, {Game, name: via_tuple(game_name)})

    # Let the lobby know a new game was created so it can refresh its list
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "lobby", :update)

    # We push patch since we're using this same live view, just updating params
    # We could get rid of one redirect if we also assigned a player id here - but for now this is cleaner logic to deal with
    # Update params, which will trigger handle_params for game being present but no player
    {:noreply,
     push_patch(
       socket,
       to:
         YookerWeb.Router.Helpers.live_path(socket, YookerWeb.GameLive,
           game: game_name,
           player: player
         )
     )}
  end

  # If for some reason they didn't pick a player name, we'll make one for them
  def handle_params(_params, _url, socket) do
    player = generate_name()

    # We push patch since we're using this same live view, just updating params
    {:noreply,
     push_patch(
       socket,
       to: YookerWeb.Router.Helpers.live_path(socket, YookerWeb.GameLive, player: player)
     )}
  end

  defp generate_name() do
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
  def handle_event("reset-game", _event, %{assigns: %{name: name}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:reset_game})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "game-" <> name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("claim-seat", %{"seat" => seat}, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:claim_seat, seat, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "game-" <> name, :update)
    # Lobby lists who is currently in seat, let the lobby know to update their listing
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "lobby", :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("deal", _event, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:deal, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "game-" <> name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event(
        "choose-trump",
        %{"suit" => suit},
        %{assigns: %{name: name, pid: pid}} = socket
      ) do
    :ok = GenServer.cast(via_tuple(name), {:choose_trump, suit, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "game-" <> name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("pass-trump", _event, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:pass_trump, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "game-" <> name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("play-card", %{"card" => card}, %{assigns: %{name: name, pid: pid}} = socket) do
    :ok = GenServer.cast(via_tuple(name), {:play_card, card, pid})
    :ok = Phoenix.PubSub.broadcast(Yooker.PubSub, "game-" <> name, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_info(:update, socket) do
    {:noreply, assign_game(socket)}
  end
end
