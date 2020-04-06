defmodule Yooker.StateTest do
	alias Yooker.State
	use ExUnit.Case
	doctest Yooker.State
  require Logger

  describe "can_play_card/2" do
    test "can only play cards from their own hand" do
      # all of these values can be randomized
      player_hands = %{
        a: ["9♠", "Q♥", "A♠", "10♣", "K♦"],
        b: ["10♥", "J♦", "A♥", "A♣", "9♣"],
        c: ["J♣", "Q♠", "A♦", "9♥", "J♠"],
        d: ["Q♦", "Q♣", "K♥", "10♦", "K♠"]
      }
      turn =  0
      play_order = [:a,:b,:c, :d]

      state = %State{
        player_hands: player_hands,
        current_round: :playing,
        turn: turn,
        play_order: play_order
      }

      for {player, hand} <- player_hands do
        for card <- hand do
          if player == Enum.at(play_order, turn) do
            #assert State.can_play_card?(state, card) == true
            # They might not be able to play all their cards - let's just focus on other hands
          else
            assert State.can_play_card?(state, card) == false
          end
        end
      end
    end

    test "can play any card if they lead" do
      player_hands = %{ # this can be randomized, as can deck
        a: ["9♠", "Q♥", "A♠", "10♣", "K♦"],
        b: ["10♥", "J♦", "A♥", "A♣", "9♣"],
        c: ["J♣", "Q♠", "A♦", "9♥", "J♠"],
        d: ["Q♦", "Q♣", "K♥", "10♦", "K♠"]
      }
      turn =  0 # first turn
      play_order = [:a,:b,:c, :d] # and A is first turn

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
        a: ["Q♥", "A♠", "9♠", "K♦"],
        b: ["10♥", "Q♠", "A♥", "A♣", "9♣"],
        c: ["J♣", "J♦", "A♦", "9♥", "J♠"],
        d: ["Q♦", "Q♣", "K♥", "10♦", "K♠"]
      }
      table = %{
        a: "10♣",
        b: nil,
        c: nil,
        d: nil
      }
      turn =  1 # player a has already led a 10 of clubs
      play_order = [:a,:b,:c, :d]

      state = %State{
        player_hands: player_hands,
        current_round: :playing,
        turn: turn,
        table: table,
        play_order: play_order
      }

      assert State.can_play_card?(state, "A♣") == true
      assert State.can_play_card?(state, "9♣") == true
      assert State.can_play_card?(state, "10♥") == false
      assert State.can_play_card?(state, "Q♠") == false
      assert State.can_play_card?(state, "A♥") == false

      # Diamonds led instead, now nothing can be played
      state = %{state | table: %{a: "K♦"}}
      assert State.can_play_card?(state, "A♣") == true
      assert State.can_play_card?(state, "9♣") == true
      assert State.can_play_card?(state, "10♥") == true
      assert State.can_play_card?(state, "Q♠") == true
      assert State.can_play_card?(state, "A♥") == true
    end

    test "left bower is treated like trump suit for following" do
      player_hands = %{
        a: ["Q♥", "J♦", "9♠", "K♦", "10♣"],
        b: ["10♥","A♥", "A♣", "9♣"],
        c: ["J♣", "A♠", "A♦", "9♥", "J♠"],
        d: ["Q♦", "Q♣", "K♥", "10♦", "K♠"]
      }
      table = %{
        a: nil,
        b: "Q♠",
        c: nil,
        d: nil
      }
      turn = 1
      play_order = [:b, :c, :d, :a]

      state = %State{
        player_hands: player_hands,
        current_round: :playing,
        turn: turn,
        trump: "♠",
        table: table,
        play_order: play_order
      }

      assert State.can_play_card?(state, "J♣") == true
      assert State.can_play_card?(state, "A♠") == true
      assert State.can_play_card?(state, "A♦") == false
      assert State.can_play_card?(state, "9♥") == false
      assert State.can_play_card?(state, "J♠") == true
    end
  end

	describe "score_hand/1" do
		test "low trump beats all other cards" do
      state = %State{
        table: %{
          a: "A♠",
          b: "9♥",
          c: "A♦",
          d: "9♣"
        },
        trump: "♣",
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
          a: "A♠",
          b: "9♥",
          c: "A♣",
          d: "J♣"
        },
        trump: "♣",
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
          a: "A♠",
          b: "J♥",
          c: "J♣",
          d: "A♣"
        },
        trump: "♣",
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
          a: "A♠",
          b: "J♥",
          c: "J♠",
          d: "A♣"
        },
        trump: "♣",
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
          a: "9♠",
          b: "A♥",
          c: "A♦",
          d: "K♥",
        },
        trump: "♣",
        play_order: [:a, :b, :c, :d]
      }

      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 1
      assert length(Map.get(tricks_taken, :b)) == 0
      assert length(Map.get(tricks_taken, :c)) == 0
      assert length(Map.get(tricks_taken, :d)) == 0

      state = %State{
        table: %{
          a: "A♥",
          b: "9♠",
          c: "A♦",
          d: "K♥",
        },
        trump: "♣",
        play_order: [:b, :c, :d, :a]
      }
      %State{tricks_taken: tricks_taken} = State.score_trick(state)
      assert length(Map.get(tricks_taken, :a)) == 0
      assert length(Map.get(tricks_taken, :b)) == 1
      assert length(Map.get(tricks_taken, :c)) == 0
      assert length(Map.get(tricks_taken, :d)) == 0
		end
	end
end
