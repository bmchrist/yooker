defmodule Yooker.State do
  require Logger

  alias Yooker.State

  defstruct kitty: [],
            player_hands: %{a: [], b: [], c: [], d: []},
            trump: nil,
            # todo - better name - TODO - can you add validators?
            current_round: :deal,
            table: %{a: nil, b: nil, c: nil, d: nil},
            tricks_taken: %{a: [], b: [], c: [], d: []},
            score: %{ac: 0, bd: 0},
            trump_selector: nil,
            # TODO(bmchrist) randomize later
            dealer: :a,
            play_order: [:b, :c, :d, :a],
            turn: 0

  @deck [
    "9♠",
    "10♠",
    "J♠",
    "Q♠",
    "K♠",
    "A♠",
    "9♥",
    "10♥",
    "J♥",
    "Q♥",
    "K♥",
    "A♥",
    "9♣",
    "10♣",
    "J♣",
    "Q♣",
    "K♣",
    "A♣",
    "9♦",
    "10♦",
    "J♦",
    "Q♦",
    "K♦",
    "A♦"
  ]

  # Currently not dealing according to proper euchre rules.. eg 3 2 3 2
  # TODO(bmchrist): Follow Euchre rules :)
  def deal(%State{} = state) do
    deck = Enum.shuffle(@deck)

    hands = Enum.chunk_every(deck, 5)

    player_hands = %{a: [], b: [], c: [], d: []}

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
    {new_round, turn} =
      if turn == 3 do
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
  def choose_trump(
        %State{
          kitty: kitty,
          player_hands: player_hands,
          current_round: current_round,
          dealer: dealer
        } = state,
        suit
      ) do
    state = %{state | turn: 0, trump_selector: current_turn_player(state)}

    # Round One -- use top card
    if current_round == :trump_select_round_two do
      if suit == "" do
        Logger.error("No suit selected when suit selection needed")
      end

      %{state | trump: suit, current_round: :playing}
    else
      if suit != "" do
        Logger.error("Suit selected when incorrect round")
      end

      {top_card, new_kitty} = List.pop_at(kitty, 0)
      new_player_hands = %{player_hands | dealer => [top_card | Map.get(player_hands, dealer)]}

      %{
        state
        | kitty: new_kitty,
          trump: get_suit_of_card(top_card, nil),
          player_hands: new_player_hands,
          current_round: :dealer_discard
      }
    end
  end

  # Allows playing a card to the table, or discarding a card if you're the dealer and have picked up trump
  # Will also ensure the cad can be played /discarded
  def play_card(%State{current_round: :playing} = state, card) do
    if !State.can_play_card?(state, card) do
      raise "Card selected cannot be played!"
    end

    play_card_to_table(state, card)
  end

  def play_card(%State{current_round: :dealer_discard} = state, card) do
    if !State.can_play_card?(state, card) do
      raise "Card selected cannot be played!"
    end

    discard_card_to_kitty(state, card)
  end

  def play_card(%State{}, _card), do: raise("Invalid round for play_card to be called during")

  # Only called when discarding after picking up trump - let the dealer discard a card after trump was selected
  defp discard_card_to_kitty(%State{kitty: kitty, player_hands: player_hands} = state, card) do
    # Get current player's hand
    current_player = current_turn_player(state)
    current_player_hand = Map.get(player_hands, current_player)

    # Take the card out of their hand...
    new_player_hand = List.delete(current_player_hand, card)
    new_player_hands = %{player_hands | current_player => new_player_hand}

    # and put it back into the kitty
    new_kitty = [card | kitty]

    %{state | kitty: new_kitty, player_hands: new_player_hands, current_round: :playing}
  end

  # Takes the card submitted from the players hand and then plays it. Advances to scoring if that was the last trick
  defp play_card_to_table(
         %State{player_hands: player_hands, turn: turn, table: table, current_round: round} =
           state,
         card
       ) do
    # Get current player's hand
    current_player = current_turn_player(state)
    current_player_hand = Map.get(player_hands, current_player)

    # Take the card out of their hand...
    new_player_hand = List.delete(current_player_hand, card)
    new_player_hands = %{player_hands | current_player => new_player_hand}

    # and put it on the table
    new_table = %{table | current_player => card}

    # If everyone has played
    # otherwise keep on with the same round
    round =
      if turn == 3 do
        # this just leads to play-card in game_live calling score_trick - could simplify logic
        :scoring
      else
        round
      end

    %{
      state
      | player_hands: new_player_hands,
        table: new_table,
        turn: turn + 1,
        current_round: round
    }
  end

  def score_hand(
        %State{
          trump_selector: trump_selector,
          tricks_taken: tricks_taken,
          score: score,
          dealer: dealer
        } = state
      ) do
    next_dealer = Enum.at(get_next_hand_order(dealer), 1)
    play_order = get_next_hand_order(next_dealer)

    # Score the hand
    # Count up tricks by team
    # If that team chose trump
    count_tricks =
      tricks_taken
      |> Enum.map(fn {player, tricks} -> {player, length(tricks)} end)
      |> Enum.into(%{})

    ac_score = Map.get(count_tricks, :a) + Map.get(count_tricks, :c)
    bd_score = Map.get(count_tricks, :b) + Map.get(count_tricks, :d)

    new_score =
      cond do
        # If anyone got all 5 tricks, 2 points
        ac_score == 5 ->
          %{score | ac: Map.get(score, :ac) + 2}

        bd_score == 5 ->
          %{score | bd: Map.get(score, :bd) + 2}

        # If anyone got all 5 tricks, 2 points
        ac_score >= 3 and (trump_selector == :b or trump_selector == :d) ->
          %{score | ac: Map.get(score, :ac) + 2}

        bd_score >= 3 and (trump_selector == :a or trump_selector == :c) ->
          %{score | bd: Map.get(score, :bd) + 2}

        ac_score >= 3 ->
          %{score | ac: Map.get(score, :ac) + 1}

        bd_score >= 3 ->
          %{score | bd: Map.get(score, :bd) + 1}

        true ->
          raise "Invalid tricks for scoring"
      end

    %{
      state
      | trump_selector: nil,
        trump: nil,
        score: new_score,
        dealer: next_dealer,
        play_order: play_order,
        current_round: :deal,
        tricks_taken: %{a: [], b: [], c: [], d: []}
    }
  end

  # Takes the table, what trump is, who led, and the tricks taken
  # Finds the best card, gives a point to that team, clears the table, and passes turn to the winning player
  def score_trick(
        %State{table: table, tricks_taken: tricks_taken, trump: trump, play_order: play_order} =
          state
      ) do
    # Card led by the first player is the leading suit
    first_player = Enum.at(play_order, 0)

    suit_led = get_suit_of_card(table[first_player], trump)

    best_player =
      Enum.at(play_order, get_best_player_index(table, play_order, 0, 1, suit_led, trump))

    tricks_taken = %{tricks_taken | best_player => [table | Map.get(tricks_taken, best_player)]}

    %{
      state
      | current_round: :playing,
        play_order: get_next_hand_order(best_player),
        tricks_taken: tricks_taken,
        turn: 0,
        table: %{a: nil, b: nil, c: nil, d: nil}
    }
  end

  defp get_best_player_index(
         table,
         play_order,
         best_player_index,
         competitor_index,
         suit_led,
         trump
       ) do
    if competitor_index <= 3 do
      if first_card_wins?(
           table[Enum.at(play_order, best_player_index)],
           table[Enum.at(play_order, competitor_index)],
           suit_led,
           trump
         ) do
        get_best_player_index(
          table,
          play_order,
          best_player_index,
          competitor_index + 1,
          suit_led,
          trump
        )
      else
        get_best_player_index(
          table,
          play_order,
          competitor_index,
          competitor_index + 1,
          suit_led,
          trump
        )
      end
    else
      best_player_index
    end
  end

  # Checks which card is the strongest - returns true if it's the first one
  # Assumes both cards are legal plays
  defp first_card_wins?(first_card, second_card, leading_suit, trump) do
    get_score_for_card(first_card, leading_suit, trump) >
      get_score_for_card(second_card, leading_suit, trump)
  end

  defp get_score_for_card(card, leading_suit, trump) do
    # Get the value and suit for the card we want to score
    # this handles the left bower on its own, get face value of suit
    suit = get_suit_of_card(card, nil)
    value = get_value_of_card(card)

    # Face Values
    # TODO would cond do be more efficient here?

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
    multiplier =
      cond do
        value == "J" and suit == trump -> 1000
        value == "J" and suit == get_left_suit(trump) -> 100
        suit == trump -> 10
        suit == leading_suit -> 1
        true -> 0
      end

    multiplier * face_value(value)
  end

  # If it is the current player's turn and they are allowed to play the card
  # TODO - this is not super readable, and a little bug-prone. add tests and clean up
  def can_play_card?(
        %State{
          player_hands: player_hands,
          trump: trump,
          play_order: play_order,
          turn: turn,
          current_round: :playing,
          table: table
        } = state,
        card
      ) do
    allowed_hand = Map.get(player_hands, current_turn_player(state))

    # and that card has to be part of the current player's hand
    Enum.member?(allowed_hand, card) &&
      (
        suit_led =
          if turn > 0 do
            get_suit_of_card(Map.get(table, Enum.at(play_order, 0)), trump)
          else
            nil
          end

        suits_in_hand = for card <- allowed_hand, do: get_suit_of_card(card, trump)

        # Card follows suit?
        # The first card can be anything
        # If this card's suit matches the suit of the card of the first player
        # Or if the player cannot follow suit, they can play anything
        turn == 0 or
          get_suit_of_card(card, trump) == suit_led or
          !Enum.member?(suits_in_hand, suit_led)
      )
  end

  def can_play_card?(
        %State{
          dealer: dealer,
          player_hands: player_hands,
          current_round: :dealer_discard
        },
        card
      ) do
    # that card has to be part of the dealer's hand
    allowed_hand = Map.get(player_hands, dealer)
    Enum.member?(allowed_hand, card)
  end

  def can_play_card?(%State{}, _card), do: false

  def show_top_card?(%State{current_round: current_round}) do
    current_round == :trump_select_round_one
  end

  # Allows someone to pass if it's the first round. Allows everyone except dealer to pass on the second
  def can_pass?(%State{current_round: current_round, turn: turn}) do
    # round two, the dealer must deal
    current_round == :trump_select_round_one or
      (current_round == :trump_select_round_two and !(turn == 3))
  end

  def current_turn_player(%State{current_round: :dealer_discard, dealer: dealer}), do: dealer

  def current_turn_player(%State{play_order: play_order, turn: turn}) do
    Enum.at(play_order, turn)
  end

  defp get_next_hand_order(:a), do: [:a, :b, :c, :d]
  defp get_next_hand_order(:b), do: [:b, :c, :d, :a]
  defp get_next_hand_order(:c), do: [:c, :d, :a, :b]
  defp get_next_hand_order(:d), do: [:d, :a, :b, :c]
  defp get_next_hand_order(true), do: raise("Unexpected first_player for play order")

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

  defp get_left_suit("♠"), do: "♣"
  defp get_left_suit("♣"), do: "♠"
  defp get_left_suit("♥"), do: "♦"
  defp get_left_suit("♦"), do: "♥"

  defp face_value("A"), do: 14
  defp face_value("K"), do: 13
  defp face_value("Q"), do: 12
  defp face_value("J"), do: 11
  defp face_value("10"), do: 10
  defp face_value("9"), do: 9
end
