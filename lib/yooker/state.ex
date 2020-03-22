defmodule Yooker.State do
  @moduledoc """
  A struct to describe the current state in the game, and functions to update
  the state by playing cards and to check if a certain move is legal.

  ## Attributes
  """
  require Logger

  alias Yooker.State

  defstruct deck: [
      "9♠", "10♠", "J♠", "Q♠", "K♠", "A♠",
      "9♣", "10♣", "J♣", "Q♣", "K♣", "A♣",
      "9♥", "10♥", "J♥", "Q♥", "K♥", "A♥",
      "9♦", "10♦", "J♦", "Q♦", "K♦", "A♦"
    ],
    player_hands: %{ a: [], b: [], c: [], d: [] }, # needs to be private..? or are these already by default?
    current_turn: nil, # rename to better indicate it will reference a player
    table: {} # could get replaced by a "selected card per player" concept..?

  def deal(%State{deck: deck, player_hands: player_hands} = state) do # TODO(bmchrist) do I need the state's whole def..? - perhaps only variables I need?
    Logger.info(deck)
    deck = Enum.shuffle(deck)

    hands = Enum.chunk_every(deck, 5)

    Logger.info(inspect(hands))
    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | a: player_hand}

    Logger.info(inspect(hands))
    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | b: player_hand}

    Logger.info(inspect(hands))
    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | c: player_hand}

    Logger.info(inspect(hands))
    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | d: player_hand}

    Logger.info(inspect(hands))
    {deck, _remain} = List.pop_at(hands, 0)
    %{state | player_hands: player_hands, deck: deck}
  end
end
