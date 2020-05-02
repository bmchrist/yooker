defmodule Yooker.StateTest do
  use ExUnit.Case

  alias Yooker.Card
  alias Yooker.State

  doctest Yooker.State

  require Logger

  describe "deal/0" do
    setup do
      state = State.deal(%State{})
      {:ok, state: state}
    end

    test "deals 5 cards to each player", %{state: state} do
      Enum.each(state.player_hands, fn {_, hand} -> assert length(hand) == 5 end)
    end

    test "puts remainder of deck into kitty", %{state: state} do
      assert length(state.kitty) == 4
    end

    test "advances round", %{state: state} do
      assert :trump_select_round_one = state.current_round
    end
  end

  describe "can_play_card/2" do
    test "can only play cards from their own hand" do
      # all of these values can be randomized
      player_hands = %{
        a: [
          %Card{suit: :spades, value: :nine},
          %Card{suit: :hearts, value: :queen},
          %Card{suit: :spades, value: :ace},
          %Card{suit: :clubs, value: :ten},
          %Card{suit: :diamonds, value: :king}
        ],
        b: [
          %Card{suit: :hearts, value: :ten},
          %Card{suit: :diamonds, value: :jack},
          %Card{suit: :hearts, value: :ace},
          %Card{suit: :clubs, value: :ace},
          %Card{suit: :clubs, value: :nine}
        ],
        c: [
          %Card{suit: :clubs, value: :jack},
          %Card{suit: :spades, value: :queen},
          %Card{suit: :diamonds, value: :ace},
          %Card{suit: :hearts, value: :nine},
          %Card{suit: :spades, value: :jack}
        ],
        d: [
          %Card{suit: :diamonds, value: :queen},
          %Card{suit: :clubs, value: :queen},
          %Card{suit: :hearts, value: :king},
          %Card{suit: :diamonds, value: :ten},
          %Card{suit: :spades, value: :king}
        ]
      }

      turn = 0
      play_order = [:a, :b, :c, :d]

      state = %State{
        player_hands: player_hands,
        current_round: :playing,
        turn: turn,
        play_order: play_order
      }

      for {player, hand} <- player_hands do
        for card <- hand do
          if player == State.current_turn_player(state) do
            # assert State.can_play_card?(state, card) == true
            # They might not be able to play all their cards - let's just focus on other hands
          else
            assert State.can_play_card?(state, card) == false
          end
        end
      end
    end

    test "can play any card if they lead" do
      # this can be randomized, as can deck
      player_hands = %{
        a: [
          %Card{suit: :spades, value: :nine},
          %Card{suit: :hearts, value: :queen},
          %Card{suit: :spades, value: :ace},
          %Card{suit: :clubs, value: :ten},
          %Card{suit: :diamonds, value: :king}
        ],
        b: [
          %Card{suit: :hearts, value: :ten},
          %Card{suit: :diamonds, value: :jack},
          %Card{suit: :hearts, value: :ace},
          %Card{suit: :clubs, value: :ace},
          %Card{suit: :clubs, value: :nine}
        ],
        c: [
          %Card{suit: :clubs, value: :jack},
          %Card{suit: :spades, value: :queen},
          %Card{suit: :diamonds, value: :ace},
          %Card{suit: :hearts, value: :nine},
          %Card{suit: :spades, value: :jack}
        ],
        d: [
          %Card{suit: :diamonds, value: :queen},
          %Card{suit: :clubs, value: :queen},
          %Card{suit: :hearts, value: :king},
          %Card{suit: :diamonds, value: :ten},
          %Card{suit: :spades, value: :king}
        ]
      }

      # first turn
      turn = 0
      # and A is first turn
      play_order = [:a, :b, :c, :d]

      state = %State{
        player_hands: player_hands,
        current_round: :playing,
        turn: turn,
        play_order: play_order
      }

      for card <- Map.get(player_hands, :a) do
        assert State.can_play_card?(state, card)
      end
    end

    test "must play a card that follows suit - if they have one - otherwise can play anything" do
      player_hands = %{
        a: [
          %Card{suit: :hearts, value: :queen},
          %Card{suit: :spades, value: :ace},
          %Card{suit: :spades, value: :nine},
          %Card{suit: :diamonds, value: :king}
        ],
        b: [
          %Card{suit: :hearts, value: :ten},
          %Card{suit: :spades, value: :queen},
          %Card{suit: :hearts, value: :ace},
          %Card{suit: :clubs, value: :ace},
          %Card{suit: :clubs, value: :nine}
        ],
        c: [
          %Card{suit: :clubs, value: :jack},
          %Card{suit: :diamonds, value: :jack},
          %Card{suit: :diamonds, value: :ace},
          %Card{suit: :hearts, value: :nine},
          %Card{suit: :spades, value: :jack}
        ],
        d: [
          %Card{suit: :diamonds, value: :queen},
          %Card{suit: :clubs, value: :queen},
          %Card{suit: :hearts, value: :king},
          %Card{suit: :diamonds, value: :ten},
          %Card{suit: :spades, value: :king}
        ]
      }

      table = %{
        a: %Card{suit: :clubs, value: :ten},
        b: nil,
        c: nil,
        d: nil
      }

      # player a has already led a 10 of clubs
      turn = 1
      play_order = [:a, :b, :c, :d]

      state = %State{
        player_hands: player_hands,
        current_round: :playing,
        turn: turn,
        table: table,
        play_order: play_order
      }

      assert State.can_play_card?(state, %Card{suit: :clubs, value: :ace}) == true
      assert State.can_play_card?(state, %Card{suit: :clubs, value: :nine}) == true
      assert State.can_play_card?(state, %Card{suit: :hearts, value: :ten}) == false
      assert State.can_play_card?(state, %Card{suit: :spades, value: :queen}) == false
      assert State.can_play_card?(state, %Card{suit: :hearts, value: :ace}) == false

      # Diamonds led instead, now anything can be played
      state = %{state | table: %{a: %Card{suit: :diamonds, value: :king}}}
      assert State.can_play_card?(state, %Card{suit: :clubs, value: :ace}) == true
      assert State.can_play_card?(state, %Card{suit: :clubs, value: :nine}) == true
      assert State.can_play_card?(state, %Card{suit: :hearts, value: :ten}) == true
      assert State.can_play_card?(state, %Card{suit: :spades, value: :queen}) == true
      assert State.can_play_card?(state, %Card{suit: :hearts, value: :ace}) == true
    end

    test "left bower is treated like trump suit for following" do
      player_hands = %{
        a: [
          %Card{suit: :hearts, value: :queen},
          %Card{suit: :diamonds, value: :jack},
          %Card{suit: :spades, value: :nine},
          %Card{suit: :diamonds, value: :king},
          %Card{suit: :clubs, value: :ten}
        ],
        b: [
          %Card{suit: :hearts, value: :ten},
          %Card{suit: :hearts, value: :ace},
          %Card{suit: :clubs, value: :ace},
          %Card{suit: :clubs, value: :nine}
        ],
        c: [
          %Card{suit: :clubs, value: :jack},
          %Card{suit: :spades, value: :ace},
          %Card{suit: :diamonds, value: :ace},
          %Card{suit: :hearts, value: :nine},
          %Card{suit: :spades, value: :jack}
        ],
        d: [
          %Card{suit: :diamonds, value: :queen},
          %Card{suit: :clubs, value: :queen},
          %Card{suit: :hearts, value: :king},
          %Card{suit: :diamonds, value: :ten},
          %Card{suit: :spades, value: :king}
        ]
      }

      table = %{
        a: nil,
        b: %Card{suit: :spades, value: :queen},
        c: nil,
        d: nil
      }

      turn = 1
      play_order = [:b, :c, :d, :a]

      state = %State{
        player_hands: player_hands,
        current_round: :playing,
        turn: turn,
        trump: :spades,
        table: table,
        play_order: play_order
      }

      assert State.can_play_card?(state, %Card{suit: :clubs, value: :jack}) == true
      assert State.can_play_card?(state, %Card{suit: :spades, value: :ace}) == true
      assert State.can_play_card?(state, %Card{suit: :diamonds, value: :ace}) == false
      assert State.can_play_card?(state, %Card{suit: :hearts, value: :nine}) == false
      assert State.can_play_card?(state, %Card{suit: :spades, value: :jack}) == true
    end
  end

  describe "score_trick/1" do
    test "low trump beats all other cards" do
      state = %State{
        table: %{
          a: %Card{suit: :spades, value: :ace},
          b: %Card{suit: :hearts, value: :nine},
          c: %Card{suit: :diamonds, value: :ace},
          d: %Card{suit: :clubs, value: :nine}
        },
        trump: :clubs,
        play_order: [:a, :b, :c, :d]
      }

      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 0
      assert length(Map.get(tricks_taken, :b)) == 0
      assert length(Map.get(tricks_taken, :c)) == 0
      assert length(Map.get(tricks_taken, :d)) == 1
    end

    test "right bower beats higher face value trump" do
      state = %State{
        table: %{
          a: %Card{suit: :spades, value: :ace},
          b: %Card{suit: :hearts, value: :nine},
          c: %Card{suit: :clubs, value: :ace},
          d: %Card{suit: :clubs, value: :jack}
        },
        trump: :clubs,
        play_order: [:a, :b, :c, :d]
      }

      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 0
      assert length(Map.get(tricks_taken, :b)) == 0
      assert length(Map.get(tricks_taken, :c)) == 0
      assert length(Map.get(tricks_taken, :d)) == 1
    end

    test "right bower beats left bower" do
      state = %State{
        table: %{
          a: %Card{suit: :spades, value: :ace},
          b: %Card{suit: :hearts, value: :jack},
          c: %Card{suit: :clubs, value: :jack},
          d: %Card{suit: :clubs, value: :ace}
        },
        trump: :clubs,
        play_order: [:a, :b, :c, :d]
      }

      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 0
      assert length(Map.get(tricks_taken, :b)) == 0
      assert length(Map.get(tricks_taken, :c)) == 1
      assert length(Map.get(tricks_taken, :d)) == 0
    end

    test "left bower beats high trump" do
      state = %State{
        table: %{
          a: %Card{suit: :spades, value: :ace},
          b: %Card{suit: :hearts, value: :jack},
          c: %Card{suit: :spades, value: :jack},
          d: %Card{suit: :clubs, value: :ace}
        },
        trump: :clubs,
        play_order: [:a, :b, :c, :d]
      }

      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 0
      assert length(Map.get(tricks_taken, :b)) == 0
      assert length(Map.get(tricks_taken, :c)) == 1
      assert length(Map.get(tricks_taken, :d)) == 0
    end

    test "low card led beats non trump" do
      state = %State{
        table: %{
          a: %Card{suit: :spades, value: :nine},
          b: %Card{suit: :hearts, value: :ace},
          c: %Card{suit: :diamonds, value: :ace},
          d: %Card{suit: :hearts, value: :king}
        },
        trump: :clubs,
        play_order: [:a, :b, :c, :d]
      }

      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 1
      assert length(Map.get(tricks_taken, :b)) == 0
      assert length(Map.get(tricks_taken, :c)) == 0
      assert length(Map.get(tricks_taken, :d)) == 0

      state = %State{
        table: %{
          a: %Card{suit: :hearts, value: :ace},
          b: %Card{suit: :spades, value: :nine},
          c: %Card{suit: :diamonds, value: :ace},
          d: %Card{suit: :hearts, value: :king}
        },
        trump: :clubs,
        play_order: [:b, :c, :d, :a]
      }

      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 0
      assert length(Map.get(tricks_taken, :b)) == 1
      assert length(Map.get(tricks_taken, :c)) == 0
      assert length(Map.get(tricks_taken, :d)) == 0
    end
  end

  describe "score_hand/1" do
    test "team that called trump gets 1 point for getting 3 or 4 tricks" do
      state = %State{
        # 3 tricks
        tricks_taken: %{a: [%{}, %{}], b: [], c: [%{}], d: [%{}, %{}]},
        score: %{ac: 3, bd: 3},
        trump_selector: :a
      }

      %State{score: new_score} = State.score_hand(state)
      assert Map.get(new_score, :ac) == 4
      assert Map.get(new_score, :bd) == 3

      state = %State{
        # 3 tricks
        tricks_taken: %{a: [%{}, %{}, %{}], b: [], c: [%{}], d: [%{}]},
        score: %{ac: 3, bd: 3},
        trump_selector: :c
      }

      %State{score: new_score} = State.score_hand(state)
      assert Map.get(new_score, :ac) == 4
      assert Map.get(new_score, :bd) == 3
    end

    test "team that called trump gets 2 points for getting 5 tricks" do
      state = %State{
        # 3 tricks
        tricks_taken: %{a: [%{}, %{}, %{}], b: [], c: [%{}, %{}], d: []},
        score: %{ac: 3, bd: 3},
        trump_selector: :c
      }

      %State{score: new_score} = State.score_hand(state)
      assert Map.get(new_score, :ac) == 5
      assert Map.get(new_score, :bd) == 3
    end

    test "team that didn't call trump gets 2 points for 3-5 tricks" do
      state = %State{
        # 3 tricks
        tricks_taken: %{a: [%{}, %{}], b: [], c: [%{}], d: [%{}, %{}]},
        score: %{ac: 3, bd: 3},
        trump_selector: :b
      }

      %State{score: new_score} = State.score_hand(state)
      assert Map.get(new_score, :ac) == 5
      assert Map.get(new_score, :bd) == 3

      state = %State{
        # 3 tricks
        tricks_taken: %{a: [%{}, %{}], b: [], c: [%{}, %{}, %{}], d: []},
        score: %{ac: 3, bd: 3},
        trump_selector: :b
      }

      %State{score: new_score} = State.score_hand(state)
      assert Map.get(new_score, :ac) == 5
      assert Map.get(new_score, :bd) == 3
    end
  end
end
