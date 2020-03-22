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
    trump: nil,
    current_turn: :a, # rename to better indicate it will reference a player
    _table: {} # could get replaced by a "selected card per player" concept..?

  # Assumes a full deck of cards. Currently errors if attempted with less than 20 cards left in deck
  # Also not dealing according to proper euchre rules..
  # TODO(bmchrist): Follow Euchre rules :)
  # TODO(bmchrist): Error handling - not full deck, already dealt
  def deal(%State{deck: deck, player_hands: player_hands} = state) do # TODO(bmchrist) do I need the state's whole def..? - perhaps only variables I need?
    deck = Enum.shuffle(deck)

    hands = Enum.chunk_every(deck, 5)

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | a: player_hand}

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | b: player_hand}

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | c: player_hand}

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | d: player_hand}

    {deck, _remain} = List.pop_at(hands, 0)
    %{state | player_hands: player_hands, deck: deck}
  end

  def advance_turn(%State{current_turn: current_turn} = state) do
    %{state | current_turn:
      case current_turn do
        :a -> :b
        :b -> :c
        :c -> :d
        :d -> :a
      end
    }
  end

  def choose_trump(%State{deck: deck} = state) do
    %{state | trump: String.last(List.first(deck))}
  end
end
