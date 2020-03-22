defmodule Yooker.State do
  @moduledoc """
  A struct to describe the current state in the game, and functions to update
  the state by playing cards and to check if a certain move is legal.

  ## Attributes
  """
  require Logger

  alias Yooker.State

  defstruct deck: ["9", "10", "J", "Q", "K", "A", "9", "10", "J", "Q", "K", "A","9", "10", "J", "Q", "K", "A" ],
    player_hands: %{ a: [], b: [], c: [], d: [] }, # needs to be private..? or are these already by default?
    current_turn: nil, # rename to better indicate it will reference a player
    table: {} # could get replaced by a "selected card per player" concept..?

  def deal(%State{deck: deck, current_turn: current_turn, table: table, player_hands: player_hands} = state) do # TODO do I need the state's whole def..? - perhaps only variables I need?
    Logger.info("deal")
    player_hands = %{
      a: ["9"],
      b: ["J"],
      c: ["A"],
      d: ["K"]
    }

    %{state | player_hands: player_hands}
  end
end
