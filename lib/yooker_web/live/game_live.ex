defmodule YookerWeb.GameLive do
  use Phoenix.LiveView
  alias Yooker.State
  require Logger

  def render(assigns) do
    YookerWeb.GameView.render("index.html", assigns)
  end

  def mount(_session, _params, socket) do # most guides don't list needing /3 (params) but does nto get called otherwise - look into this
    # TODO(bmchrist) figure out why we need to manually define the default layout)
    {:ok, assign(socket, layout: {YookerWeb.LayoutView, "app.html"}, state: %Yooker.State{})}
  end

  def handle_event("deal", _event, %{assigns: assigns} = socket) do
    new_state = State.deal(assigns.state)
    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("choose-trump", %{"suit" => suit}, %{assigns: assigns} = socket) do
    Logger.info(suit)
    new_state = State.choose_trump(assigns.state, suit)
    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("pass-trump", _event, %{assigns: assigns} = socket) do
    # todo -- handle not passing forever
    new_state = State.advance_trump_selection(assigns.state)
    {:noreply, assign(socket, state: new_state)}
  end

  def handle_event("play-card", %{"card" => card}, %{assigns: assigns} = socket) do
    new_state = State.play_card(assigns.state, card)

    # Doing this second function based on if statement feels a bit like a code smell... tbd -- TODO review
    new_state = if new_state.current_round == :scoring do
      State.score_trick(new_state)
    else
      new_state
    end

    {:noreply, assign(socket, state: new_state)}
  end
end
