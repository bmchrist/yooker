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
    table: %{a: nil, b: nil, c: nil, d: nil},
    score: %{ac: 0, bd: 0}


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

  # Takes the card submitted, checks whose turn it is, ensures the is in their hand, and then plays it
  def play_card(%State{player_hands: player_hands, current_turn: current_turn, table: table, current_round: round } = state, card) do
    # TODO - store "first card led" to allow logic on what cards can be played

    # Get current player's hand
    current_player_hand = Map.get(player_hands, current_turn)

    # We can't play a card not in our hand..
    if !Enum.member?(current_player_hand, card) do
      raise "Card not found in current player's hand!"
    end

    # Take the card out of their hand...
    new_player_hand = List.delete(current_player_hand, card)
    new_player_hands = %{player_hands | current_turn => new_player_hand}

    # and put it on the table
    new_table = %{table | current_turn => card}

    # TODO should clean up turn passing logic - for now, this either passes to next person, or
    # score round function assumes we've looped back to first player because of this
    new_turn = get_next_turn(current_turn)

    round = if Map.get(new_table, new_turn) do # If next player has already played, the round is over
      :scoring # this just leads to play-card in game_live calling score_hand - could simplify logic
    else # otherwise keep on with the same round
      round
    end

    %{state | player_hands: new_player_hands, table: new_table, current_turn: new_turn, current_round: round}
  end

  # TODO - BIG assumption, that current player is the one who led the round - relies on play_card having advanced the turn each time
  # fragile - think of better way of doing this.. - see current_order issue on GH, and see note on passing logic in play_card fn
  #
  # Takes the table, what trump is, who led, and the score
  # Finds the best card, gives a point to that team, clears the table, and passes turn to the winning player
  def score_hand(%State{table: table, trump: trump, current_turn: current_turn, score: score} = state) do

    suit_led = String.last(table[current_turn]) # TODO replace with using stored "suit led" logic (do as part of turn tracking logic update)

    # Player one - who led and set this hand's suit - starts as the best card
    best_player = current_turn

    # TODO abstract this logic into a function
    # Score against 2nd player
    next_turn = get_next_turn(current_turn)
    best_player = if first_card_wins?(table[best_player], table[next_turn], suit_led, trump) do
      Logger.info("Player #{best_player} beats Player #{next_turn}")
      best_player
    else
      Logger.info("Player #{next_turn} beats Player #{best_player}")
      next_turn
    end

    # Score winner against 3rd player
    next_turn = get_next_turn(next_turn)
    best_player = if first_card_wins?(table[best_player], table[next_turn], suit_led, trump) do
      Logger.info("Player #{best_player} beats Player #{next_turn}")
      best_player
    else
      Logger.info("Player #{next_turn} beats Player #{best_player}")
      next_turn
    end

    # Score winner against 4th player
    next_turn = get_next_turn(next_turn)
    best_player = if first_card_wins?(table[best_player], table[next_turn], suit_led, trump) do
      Logger.info("Player #{best_player} beats Player #{next_turn}")
      best_player
    else
      Logger.info("Player #{next_turn} beats Player #{best_player}")
      next_turn
    end

    Logger.info("Best Player: #{best_player}")

    # TODO: this feel gnarly... clean up logic for updating score
    # TODO: allow scoring 2 or 4 points in special cases
    score = if best_player == :a or best_player == :c do
      %{score | ac: score[:ac] + 1}
    else
      %{score | bd: score[:bd] + 1}
    end

    # Return updated score, next turn, reset back to playing for new round, and clear the table
    # TODO: store last trick in case people want to see it
    %{state | score: score, current_turn: best_player, current_round: :playing, table: %{a: nil, b: nil, c: nil, d: nil}}
  end

  # Checks which card is the strongest - returns true if it's the first one
  # Trump, then leading suit. Highest card if both have the same suit value
  defp first_card_wins?(first_card, second_card, leading_suit, trump) do
    Logger.info("Comparing #{first_card} to #{second_card}")
    first_value = String.first(first_card)
    first_suit = String.last(first_card)
    second_value = String.first(second_card)
    second_suit = String.last(second_card)

    # who has highest suit (trump, led, nil)

    # Highest trump (if they were allowed to play trump - but we could ensure that's checked in play_card function)
    # Otherwise, highest card of leading suit
    # If neither are trump, and neither of leading suit, error
    # # TODO update to handle left bower w/ new card storage
    cond do
      first_suit == second_suit -> first_card_value_higher?(first_value, second_value)
      first_suit == trump -> true
      second_suit == trump -> false
      first_suit == leading_suit -> true
      second_suit == leading_suit -> false
      # If we compare from first card through, and keep best - we should always at least have a leading suit
      true -> raise "No trump or leading suit found, when expected"
    end
  end

  # TODO obviously this does nothing useful
  defp first_card_value_higher?(first_value, second_value) do
    true # #TODO upgrade w/ new card scoring
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
