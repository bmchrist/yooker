defmodule Yooker.State do
  require Logger

  alias Yooker.State

  # TODO(bmchrist) how would I make a convenience such as getting the top card of the deck..)
  # TODO: make it's something like State.top_card(state) that just returns a card..?

  defstruct deck: [
      "9♠", "10♠", "J♠", "Q♠", "K♠", "A♠",
      "9♣", "10♣", "J♣", "Q♣", "K♣", "A♣",
      "9♥", "10♥", "J♥", "Q♥", "K♥", "A♥",
      "9♦", "10♦", "J♦", "Q♦", "K♦", "A♦"
    ],
    player_hands: %{a: [], b: [], c: [], d: [] }, # needs to be private..? or are these already by default?
    trump: nil,
    current_turn: :b, # rename to better indicate it will reference a player
    dealer: :a, # TODO(bmchrist) randomize later
    current_round: :deal, # todo - better name - TODO - can you add validators?
    play_order: [:b, :c, :d, :a],
    table: %{a: nil, b: nil, c: nil, d: nil}


  # Assumes a full deck of cards. Currently errors if attempted with less than 20 cards left in deck
  # Also not dealing according to proper euchre rules.. eg 3 2 3 2
  # TODO(bmchrist): Follow Euchre rules :)
  # TODO(bmchrist): Error handling - not full deck, already dealt
  def deal(%State{deck: deck, player_hands: player_hands} = state) do # TODO(bmchrist) do I need the state's whole def..? - perhaps only variables I need?
    if length(deck) < 24 do
      Logger.error("Trying to deal without a full deck")
    end

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

  # Moves to next player, and also checks if we need to move to round 2 selection (when card is placed
  # face down)
  def advance_trump_selection(%State{current_turn: current_turn, current_round: current_round, dealer: dealer} = state) do
    # if we're in trump selection rnd 1
    # starts left of dealer
    # if not dealer passing, just advance
    # else if dealer passing, advance round
    new_turn = get_next_turn(current_turn)

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

  # Takes selection from client for trump. Sets trump and moves to Playing round
  # If round 1 expects no suit to be spcified as we're choosing
  # based on top card. On second round expects individual to choose a suit
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

  # Takes the card submitted, checks whose turn it is, if the card is in their hand, and then plays it
  def play_card(%State{player_hands: player_hands, current_turn: current_turn, table: table, current_round: round } = state, card) do
    # Get current player's hand
    current_player_hand = Map.get(player_hands, current_turn)

    if !Enum.member?(current_player_hand, card) do
      raise "Card not found in current player's hand!"
    end

    new_player_hand = List.delete(current_player_hand, card)
    new_player_hands = %{player_hands | current_turn => new_player_hand}
    new_table = %{table | current_turn => card}

    new_turn = get_next_turn(current_turn) # TODO only if relevant.. should abstract out is dealer logic from trump function

    round = if Map.get(new_table, new_turn)do # If a card has already been played by next player
      :scoring
    else
      round # otherwise keep on with the same round
    end
    %{state | player_hands: new_player_hands, table: new_table, current_turn: new_turn, current_round: round}
  end

  # If it is the current player's turn and they are allowed to play the card
  def can_play_card?(%State{player_hands: player_hands, current_turn: current_turn, current_round: current_round}, card) do
    allowed_hand = Map.get(player_hands, current_turn)
    card_follows_suit = true # TODO(bmchrist) add ability to check if it can be played

    current_round == :playing && # Only can play a card if we're playin
      Enum.member?(allowed_hand, card) && # and that card has to be part of the current player's hand
      card_follows_suit
  end

  # TODO(bmchrist) - add tests..
  # Allows someone to pass if it's the first round. Allows everyone except dealer to pass on the second
  def can_pass?(%State{current_round: current_round, dealer: dealer, current_turn: current_turn}) do
    current_round == :trump_select_round_one or
      (current_round == :trump_select_round_two and !(current_turn == dealer))
  end

  # TODO(bmchrist) - possibly replace this with a list of "turns remaining"
  defp get_next_turn(turn) do
    case turn do
      :a -> :b
      :b -> :c
      :c -> :d
      :d -> :a
    end
  end
end
