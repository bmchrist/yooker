defmodule Yooker.State do
  require Logger

  alias Yooker.State

  defstruct kitty: [],
    player_hands: %{a: [], b: [], c: [], d: [] },
    trump: nil,
    current_round: :deal, # todo - better name - TODO - can you add validators?
    table: %{a: nil, b: nil, c: nil, d: nil},
    tricks_taken: %{a: [], b: [], c: [], d: []},
    score: %{ac: 0, bd: 0},
    trump_selector: nil,

    dealer: :a, # TODO(bmchrist) randomize later
    play_order: [:b, :c, :d, :a],
    turn: 0

  # Currently not dealing according to proper euchre rules.. eg 3 2 3 2
  # TODO(bmchrist): Follow Euchre rules :)
  def deal(%State{} = state) do
    deck = [
      "9♠", "10♠", "J♠", "Q♠", "K♠", "A♠",
      "9♥", "10♥", "J♥", "Q♥", "K♥", "A♥",
      "9♣", "10♣", "J♣", "Q♣", "K♣", "A♣",
      "9♦", "10♦", "J♦", "Q♦", "K♦", "A♦"
    ]

    deck = Enum.shuffle(deck)

    hands = Enum.chunk_every(deck, 5)

    player_hands = %{a: [], b: [], c: [], d: [] }

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | a: player_hand}

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | b: player_hand}

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | c: player_hand}

    {player_hand, hands} = List.pop_at(hands, 0)
    player_hands = %{player_hands | d: player_hand}

    {kitty, _remaining} = List.pop_at(hands, 0)
    %{state | player_hands: player_hands, kitty: kitty, current_round: :trump_select_round_one}
  end

  # Moves to next player, and also checks if we need to move to round 2 selection (when card is placed
  # face down)
  def advance_trump_selection(%State{turn: turn, current_round: current_round} = state) do
    # if we're in trump selection rnd 1
    # starts left of dealer
    # if not dealer passing, just advance
    # else if dealer passing, advance round

    # If we're advancing from turn 3, the dealer just passed. Move on to round 2 selection
    {new_round, turn} = if turn == 3 do
      if current_round == :trump_select_round_one do
        {:trump_select_round_two, 0}
      else
        # This should not happen as can_pass? will prevent dealer from passing in round two
        Logger.error("Invalid round advancement")
        {:error_round, 0}
      end
    else
      {current_round, turn + 1}
    end

    %{state | current_round: new_round, turn: turn}
  end

  # Takes selection from client for trump. Sets trump and moves to Playing round
  # If round 1 expects no suit to be spcified as we're choosing
  # based on top card. On second round expects individual to choose a suit
  def choose_trump(%State{kitty: kitty, current_round: current_round} = state, suit) do
    suit = if current_round == :trump_select_round_two do
      if suit == "" do
        Logger.error("No suit selected when suit selection needed")
      end
      suit
    else # Round One -- use top card
      if suit != "" do
        Logger.error("Suit selected when incorrect round")
      end

      get_suit_of_card(List.first(kitty), nil)
    end

    %{state | turn: 0, trump_selector: current_turn(state), trump: suit, current_round: :playing}
  end

  # Takes the card submitted, checks whose turn it is, ensures the is in their hand, and then plays it
  def play_card(%State{player_hands: player_hands, turn: turn, table: table, current_round: round } = state, card) do
    # Get current player's hand
    current_player = current_turn(state)
    current_player_hand = Map.get(player_hands, current_player)

    if !State.can_play_card?(state, card) do
      raise "Card selected cannot be played!"
    end

    # Take the card out of their hand...
    new_player_hand = List.delete(current_player_hand, card)
    new_player_hands = %{player_hands | current_player => new_player_hand}

    # and put it on the table
    new_table = %{table | current_player => card}

    round = if turn == 3 do # If everyone has played
      :scoring # this just leads to play-card in game_live calling score_trick - could simplify logic
    else # otherwise keep on with the same round
      round
    end

    %{state | player_hands: new_player_hands, table: new_table, turn: turn + 1, current_round: round}
  end

  def score_hand(%State{trump_selector: trump_selector, tricks_taken: tricks_taken, score: score, dealer: dealer} = state) do
    next_dealer = Enum.at(get_next_hand_order(dealer), 1)
    play_order = get_next_hand_order(next_dealer)

    # Score the hand
    # Count up tricks by team
    # If that team chose trump
    count_tricks = tricks_taken |> Enum.map(fn ({player, tricks}) -> {player, length(tricks)} end) |> Enum.into(%{})
    ac_score = Map.get(count_tricks, :a) + Map.get(count_tricks, :c)
    bd_score = Map.get(count_tricks, :b) + Map.get(count_tricks, :d)

    new_score = cond do
      # If anyone got all 5 tricks, 2 points
      ac_score == 5 -> %{score | ac: Map.get(score, :ac) + 2}
      bd_score == 5 -> %{score | bd: Map.get(score, :bd) + 2}

      # If anyone got all 5 tricks, 2 points
      ac_score >= 3 and (trump_selector == :b or trump_selector == :d) -> %{score | ac: Map.get(score, :ac) + 2}
      bd_score >= 3 and (trump_selector == :a or trump_selector == :c) -> %{score | bd: Map.get(score, :bd) + 2}

      ac_score >= 3 -> %{score | ac: Map.get(score, :ac) + 1}
      bd_score >= 3 -> %{score | bd: Map.get(score, :bd) + 1}

      true -> raise "Invalid tricks for scoring"
    end

    %{state | score: new_score, dealer: next_dealer, play_order: play_order, current_round: :deal, tricks_taken: %{a: [], b: [], c: [], d: []}}
  end

  # Takes the table, what trump is, who led, and the tricks taken
  # Finds the best card, gives a point to that team, clears the table, and passes turn to the winning player
  def score_trick(%State{table: table, tricks_taken: tricks_taken, trump: trump, play_order: play_order} = state) do

    # Card led by the first player is the leading suit
    first_player = Enum.at(play_order, 0)

    suit_led = get_suit_of_card(table[first_player], trump)

    best_player = Enum.at(play_order, get_best_player_index(table, play_order, 0, 1, suit_led, trump))

    tricks_taken = %{tricks_taken | best_player => [table | Map.get(tricks_taken, best_player)]}

    %{state | current_round: :playing, play_order: get_next_hand_order(best_player), tricks_taken: tricks_taken, turn: 0, table: %{a: nil, b: nil, c: nil, d: nil}}
  end

  defp get_best_player_index(table, play_order, best_player_index, competitor_index, suit_led, trump) do
    if competitor_index <= 3 do
      if first_card_wins?(table[Enum.at(play_order, best_player_index)], table[Enum.at(play_order, competitor_index)], suit_led, trump) do
        get_best_player_index(table, play_order, best_player_index, competitor_index+1, suit_led, trump)
      else
        get_best_player_index(table, play_order, competitor_index, competitor_index+1, suit_led, trump)
      end
    else
      best_player_index
    end
  end

  # Checks which card is the strongest - returns true if it's the first one
  # Assumes both cards are legal plays
  defp first_card_wins?(first_card, second_card, leading_suit, trump) do
    get_score_for_card(first_card, leading_suit, trump) > get_score_for_card(second_card, leading_suit, trump)
  end

  defp get_score_for_card(card, leading_suit, trump) do
    # Get the value and suit for the card we want to score
    suit = get_suit_of_card(card, nil) # this handles the left bower on its own, get face value of suit
    value = get_value_of_card(card)

    # Face Values
    # TODO would cond do be more efficient here?
    face_value = %{
      "A" => 14,
      "K" => 13,
      "Q" => 12,
      "J" => 11,
      "10" => 10,
      "9" => 9,
    }

    # Trump Values (see multiplier below)
    # JRight  11000
    # JLeft   1100
    # A       140
    # K       130
    # Q       120
    # 10      100
    # 9       90
    #
    # If it's the right bower, it's worth a lot
    # If it's the left bower, it's worth a little less
    # Otherwise if it's any trump, it's worth a premium on its face value
    # Otherwise if it follows suit, it's worth its face value
    # Otherwise it's worth 0 - did not follow suit
    multiplier = cond do
      value == "J" and suit == trump -> 1000
      value == "J" and suit == get_left_suit(trump) -> 100
      suit == trump -> 10
      suit == leading_suit -> 1
      true -> 0
    end

    multiplier * Map.get(face_value, value)
  end

  # If it is the current player's turn and they are allowed to play the card
  # TODO - this is not super readable, and a little bug-prone. add tests and clean up
  def can_play_card?(%State{player_hands: player_hands, trump: trump, play_order: play_order, turn: turn, current_round: current_round, table: table} = state, card) do
    allowed_hand = Map.get(player_hands, current_turn(state))

    current_round == :playing &&
      (
        Enum.member?(allowed_hand, card) # and that card has to be part of the current player's hand
      ) && (
        suit_led = if turn > 0 do
          get_suit_of_card(Map.get(table, Enum.at(play_order, 0)), trump)
        else
          nil
        end

        suits_in_hand = for card <- allowed_hand, do: get_suit_of_card(card, trump)

        # Card follows suit?
        (
          # The first card can be anything
          turn == 0 or

          # If this card's suit matches the suit of the card of the first player
          get_suit_of_card(card, trump) == suit_led or

          # Or if the player cannot follow suit, they can play anything
          !Enum.member?(suits_in_hand, suit_led)
        )
      )
  end

  # Allows someone to pass if it's the first round. Allows everyone except dealer to pass on the second
  def can_pass?(%State{current_round: current_round, turn: turn}) do
    current_round == :trump_select_round_one or
      (current_round == :trump_select_round_two and !(turn == 3)) # round two, the dealer must deal
  end

  def current_turn(%State{play_order: play_order, turn: turn}) do
    Enum.at(play_order, turn)
  end

  defp get_next_hand_order(first_player) do
    case first_player do
      :a -> [:a, :b, :c, :d]
      :b -> [:b, :c, :d, :a]
      :c -> [:c, :d, :a, :b]
      :d -> [:d, :a, :b, :c]
      true -> raise "Unexpected first_player for play order"
    end
  end

  # Returns the face value of the card
  def get_value_of_card(card) do
    String.split_at(card, -1) |> elem(0)
  end

  # Returns the suit of the card, returning the trump suit for the left bower
  # Passing nil for trump will just use the suit on the face
  def get_suit_of_card(card, trump) do
    {value, suit} = String.split_at(card, -1)
    if trump != nil and value == "J" and suit == get_left_suit(trump) do
      trump
    else
      suit
    end
  end

  defp get_left_suit(suit) do
    case suit do
      "♠" -> "♣"
      "♣" -> "♠"
      "♥" -> "♦"
      "♦" -> "♥"
    end
  end
end
