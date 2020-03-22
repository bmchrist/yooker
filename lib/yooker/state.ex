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
    current_turn: :b, # rename to better indicate it will reference a player
    dealer: :a, # TODO(bmchrist) randomize later
    current_round: :deal, # todo - better name - TODO - can you add validators?
    _table: {} # could get replaced by a "selected card per player" concept..?


  # TODO(bmchrist) how would I make a convenience such as getting the top card of the deck..)
  # TODO: make it's something like State.top_card(state) that just returns a card..?

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

    {deck, _remaining} = List.pop_at(hands, 0)
    %{state | player_hands: player_hands, deck: deck, current_round: :trump_select_round_one}
  end

  # TODO(bmchrist) Only relevant if we're still setting up the round - need new logic once we start playing
  # # Handle "stick the dealer" vs continuing to pass
  def advance_turn(%State{current_turn: current_turn, current_round: current_round, dealer: dealer} = state) do
    # if we're in trump selection rnd 1
    # starts left of dealer
    # if not dealer passing, just advance
    # else if dealer passing, advance round
    new_turn = case current_turn do
      :a -> :b
      :b -> :c
      :c -> :d
      :d -> :a
    end

    # If the dealer just advanced the turn
    new_round = if current_turn == dealer do
      if current_round == :trump_select_round_one do
        :trump_select_round_two
      else
        Logger.error("Invalid round advancement")
        :error_round
      end
    else
      current_round
    end

    %{state | current_turn: new_turn, current_round: new_round}
  end

  def choose_trump(%State{deck: deck, current_round: current_round} = state, suit) do
    suit = if current_round == :trump_select_round_two do
      if suit == "" do
        Logger.error("No suit selected when suit selection needed")
      end
      suit
    else # Round One -- use top card
      if suit != "" do
        Logger.error("Suit selected when incorrect round")
      end

      String.last(List.first(deck))
    end

    %{state | trump: suit, current_round: :playing}
  end

  # TODO - add tests..
  def can_pass?(%State{current_round: current_round, dealer: dealer, current_turn: current_turn}) do
    current_round == :trump_select_round_one or
      (current_round == :trump_select_round_two and !(current_turn == dealer))
  end
end
