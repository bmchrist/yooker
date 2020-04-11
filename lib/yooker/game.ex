# TODO decide if it's actually worthwhile to split this out from the state..
defmodule Yooker.Game do
  require Logger

  alias Yooker.Game
  alias Yooker.State

  defstruct state: %State{},
    player_assignments: %{a: nil, b: nil, c: nil, d: nil}

  use GenServer, restart: :transient

  @timeout 6_000_000 # Times out if no interaction for 100 minutes

  def start_link(options) do
    GenServer.start_link(__MODULE__, %Game{}, options)
  end

  @impl GenServer
  def init(game) do
    {:ok, game, @timeout}
  end

	@impl GenServer
  def handle_info(:timeout, game) do
    {:stop, :normal, game}
  end

  @impl GenServer
  def handle_call(:game, _from, game) do
    {:reply, game, game, @timeout}
  end

  ##################################
  # Handle game actions from players
  ##################################
  # TODO - some way to wrap these all in a check that player can actually play?
  @impl GenServer
  def handle_cast({:claim_seat, seat, pid}, %Game{player_assignments: player_assignments} = game) do
    seat_atom = String.to_existing_atom(seat) # Atom for a,b,c,d should all already exist
    {:noreply, %{game | player_assignments: %{player_assignments | seat_atom => pid}}, @timeout}
  end

  @impl GenServer
  def handle_cast({:deal, pid}, %Game{state: state} = game) do
    {:noreply, %{game | state: State.deal(state)}, @timeout}
  end

  @impl GenServer
  def handle_cast({:choose_trump, suit, pid}, %Game{state: state} = game) do
    {:noreply, %{game | state: State.choose_trump(state, suit)}, @timeout}
  end

  @impl GenServer
  def handle_cast({:pass_trump, pid}, %Game{state: state} = game) do
    {:noreply, %{game | state: State.advance_trump_selection(state)}, @timeout}
  end

  @impl GenServer
  def handle_cast({:play_card, card, pid}, %Game{state: state} = game) do
    new_state = State.play_card(state, card)

    # Doing this second function based on if statement feels a bit like a code smell... tbd -- TODO review
    new_state = if new_state.current_round == :scoring do
      State.score_trick(new_state)
    else
      new_state
    end

    # TODO improve this
    # Also TODO - improve this comment - what specifically needs to be improved?
    # Perhaps this whole concept of the controller-thing tracking this stuff - feels suboptimal
    new_state = if length(List.flatten(Map.values(new_state.tricks_taken))) == 5 do
      State.score_hand(new_state)
    else
      new_state
    end

    {:noreply, %{game | state: new_state}, @timeout}
  end

end
