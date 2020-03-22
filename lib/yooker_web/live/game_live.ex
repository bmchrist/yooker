defmodule YookerWeb.GameLive do
  use Phoenix.LiveView

  require Logger

  def render(assigns) do
    ~L"""
    <h1>LiveView is awesome!</h1>
    """
    #YookerWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, params, socket) do
    {:ok, assign(socket, state: %Yooker.State{})}
  end

  #def handle_event("deal", _event, %{assigns: assigns} = socket) do # todo - why do we do the assigns = socket thing
    #Logger.info("deal")
    #new_state = State.deal(assigns.state)
    #{:noreply, assign(socket, state: new_state)}
  #end
end
