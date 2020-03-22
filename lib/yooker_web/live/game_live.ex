defmodule YookerWeb.GameLive do
  use Phoenix.LiveView

  require Logger

  def render(assigns) do
    YookerWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, params, socket) do
    {:ok, assign(socket, state: %Yooker.State{})}
  end
end
