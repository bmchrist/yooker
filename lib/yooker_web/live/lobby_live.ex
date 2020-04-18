defmodule YookerWeb.LobbyLive do
  use Phoenix.LiveView
  require Logger

  def render(assigns) do
    YookerWeb.LobbyView.render("index.html", assigns)
  end

  def mount(_session, _params, socket) do
    :ok = Phoenix.PubSub.subscribe(Yooker.PubSub, "lobby")
    {:ok, assign_lobby(socket)}
  end

  def handle_info(:update, socket) do
    {:noreply, assign_lobby(socket)}
  end

  def handle_event(
        "join_game",
        %{"join_game" => %{"game_id" => game_id, "player_name" => player}},
        socket
      ) do
    {:noreply,
     push_redirect(
       socket,
       to:
         YookerWeb.Router.Helpers.live_path(socket, YookerWeb.GameLive,
           game: game_id,
           player: player
         )
     )}
  end

  def handle_event("create_game", %{"create_game" => %{"player_name" => player}}, socket) do
    {:noreply,
     push_redirect(
       socket,
       to: YookerWeb.Router.Helpers.live_path(socket, YookerWeb.GameLive, player: player)
     )}
  end

  defp assign_lobby(socket) do
    assign(socket, layout: {YookerWeb.LayoutView, "app.html"}, games: list_games())
  end

  defp list_games do
    for {_id, pid, _type, _modules} <- Supervisor.which_children(Yooker.GameSupervisor) do
      %{
        game_id: List.first(Registry.keys(Yooker.GameRegistry, pid)),
        game: GenServer.call(pid, :game)
      }
    end
  end
end
