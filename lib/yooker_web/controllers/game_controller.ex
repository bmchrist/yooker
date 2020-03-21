defmodule YookerWeb.GameController do
  use YookerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def show(conn, %{"player_id" => player_id}) do
    # TODO(bmchrist) later, this will just render json data and be polled by game board / index
    render(conn, "show.html", player_id: player_id)
  end
end
