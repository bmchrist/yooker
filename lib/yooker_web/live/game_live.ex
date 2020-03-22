defmodule YookerWeb.GameLive do
  use Phoenix.LiveView
  alias Yooker.State

  require Logger

  def render(assigns) do
    YookerWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, params, socket) do
    # TODO(bmchrist) figure out why we need to manually define the default layout)
    {:ok, assign(socket, layout: {YookerWeb.LayoutView, "app.html"}, state: %Yooker.State{})}
  end

  def handle_event("deal", _event, %{assigns: assigns} = socket) do # todo - why do we do the assigns = socket thing
    Logger.info("deal")
    new_state = State.deal(assigns.state)
    {:noreply, assign(socket, state: new_state)}
  end
end
