defmodule Yooker.State do
  alias Yooker.Card
  alias Yooker.Deck
  alias __MODULE__, as: State

  require Logger

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
            last_trick: %{a: nil, b: nil, c: nil, d: nil},
            turn: 0

  @deal_order [3, 2, 3, 2, 2, 3, 2, 3]

  def deal(%State{play_order: play_order, current_round: :deal} = state) do
    deck =
      Deck.new()
      |> Deck.shuffle()

    {deck, player_hands, _} =
      Enum.reduce(play_order ++ play_order, {deck, %{}, @deal_order}, fn player,
                                                                         {deck, player_hands,
                                                                          [num | deals]} ->
        {cards, deck} = deck |> Deck.take(num)
        {deck, Map.put(player_hands, player, (player_hands[player] || []) ++ cards), deals}
      end)

    %{state | player_hands: player_hands, kitty: deck, current_round: :trump_select_round_one}
  end

  # Moves to next player, and also checks if we need to move to round 2 selection (when card is placed
  # face down)
  def advance_trump_selection(%State{turn: 3, current_round: :trump_select_round_one} = state) do
    %{state | current_round: :trump_select_round_two, turn: 0}
  end

  def advance_trump_selection(%State{turn: 3} = state) do
    # This should not happen as can_pass? will prevent dealer from passing in round two
    Logger.error("Invalid round advancement")

    %{state | current_round: :error_round, turn: 0}
  end

  def advance_trump_selection(%State{turn: turn} = state) do
    %{state | turn: turn + 1}
  end

  # Takes selection from client for trump. Sets trump and moves to Playing round
  # If round 1 expects no suit to be spcified as we're choosing
  # based on top card. On second round expects individual to choose a suit
  def choose_trump(%State{current_round: :trump_select_round_two} = state, suit) do
    # Round One -- use top card
    if suit == "" do
      Logger.error("No suit selected when suit selection needed")
    end

    %{
      state
      | turn: 0,
        trump_selector: current_turn_player(state),
        trump: suit,
        current_round: :playing
    }
  end

  def choose_trump(
        %State{
          kitty: kitty,
          player_hands: player_hands,
          dealer: dealer
        } = state,
        suit
      ) do
    if suit != "" do
      Logger.error("Suit selected when incorrect round")
    end

    {top_card, new_kitty} = List.pop_at(kitty, 0)
    new_player_hands = %{player_hands | dealer => [top_card | Map.get(player_hands, dealer)]}

    %{
      state
      | turn: 0,
        trump_selector: current_turn_player(state),
        kitty: new_kitty,
        trump: top_card.suit,
        player_hands: new_player_hands,
        current_round: :dealer_discard
    }
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
    next_lead = Enum.at(get_next_hand_order(dealer), 2)
    play_order = get_next_hand_order(next_lead)

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

    suit_led = Card.trump_suit(table[first_player], trump)

    best_player =
      Enum.at(play_order, get_best_player_index(table, play_order, 0, 1, suit_led, trump))

    tricks_taken = %{tricks_taken | best_player => [table | Map.get(tricks_taken, best_player)]}

    %{
      state
      | current_round: :playing,
        play_order: get_next_hand_order(best_player),
        tricks_taken: tricks_taken,
        last_trick: table,
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
       )
       when competitor_index <= 3 do
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
  end

  defp get_best_player_index(
         _table,
         _play_order,
         best_player_index,
         _competitor_index,
         _suit_led,
         _trump
       ),
       do: best_player_index

  # Checks which card is the strongest - returns true if it's the first one
  # Assumes both cards are legal plays
  defp first_card_wins?(first_card, second_card, leading_suit, trump) do
    Card.score(first_card, leading_suit, trump) > Card.score(second_card, leading_suit, trump)
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
            Card.trump_suit(Map.get(table, Enum.at(play_order, 0)), trump)
          else
            nil
          end

        suits_in_hand = for card <- allowed_hand, do: Card.trump_suit(card, trump)

        # Card follows suit?
        # The first card can be anything
        # If this card's suit matches the suit of the card of the first player
        # Or if the player cannot follow suit, they can play anything
        turn == 0 or
          Card.trump_suit(card, trump) == suit_led or
          !Enum.member?(suits_in_hand, suit_led)
      )
  end

  def can_play_card?(
        %State{
          dealer: dealer,
          player_hands: player_hands,
          current_round: :dealer_discard
        },
        %Card{} = card
      ) do
    # that card has to be part of the dealer's hand
    Map.get(player_hands, dealer)
    |> Enum.member?(card)
  end

  def can_play_card?(%State{}, _card), do: false

  def show_top_card?(%State{current_round: :trump_select_round_one}), do: true
  def show_top_card?(%State{}), do: false
  def selecting_trump?(%State{current_round: :trump_select_round_one}), do: true
  def selecting_trump?(%State{current_round: :trump_select_round_two}), do: true
  def selecting_trump?(%State{}), do: false

  # Allows someone to pass if it's the first round. Allows everyone except dealer to pass on the second
  def can_pass?(%State{current_round: :trump_select_round_one}), do: true

  def can_pass?(%State{current_round: :trump_select_round_two, turn: turn}) when turn != 3,
    do: true

  def can_pass?(%State{}), do: false

  def current_turn_player(%State{current_round: :dealer_discard, dealer: dealer}), do: dealer

  def current_turn_player(%State{play_order: play_order, turn: turn}) do
    Enum.at(play_order, turn)
  end

  defp get_next_hand_order(:a), do: [:a, :b, :c, :d]
  defp get_next_hand_order(:b), do: [:b, :c, :d, :a]
  defp get_next_hand_order(:c), do: [:c, :d, :a, :b]
  defp get_next_hand_order(:d), do: [:d, :a, :b, :c]
  defp get_next_hand_order(_), do: raise("Unexpected first_player for play order")
end
