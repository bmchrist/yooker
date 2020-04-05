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
      Logger.warn("TODO")
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
        score: %{ac: 0, bd: 0},
        play_order: [:a, :b, :c, :d]
      }

      %State{score: score} = State.score_hand(state)
      assert Map.get(score, :ac) == 0
      assert Map.get(score, :bd) == 1
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
        score: %{ac: 0, bd: 0},
        play_order: [:a, :b, :c, :d]
      }

      %State{score: score} = State.score_hand(state)
      assert Map.get(score, :ac) == 0
      assert Map.get(score, :bd) == 1
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
        score: %{ac: 0, bd: 0},
        play_order: [:a, :b, :c, :d]
      }

      %State{score: score} = State.score_hand(state)
      assert Map.get(score, :ac) == 1
      assert Map.get(score, :bd) == 0
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
        score: %{ac: 0, bd: 0},
        play_order: [:a, :b, :c, :d]
      }

      %State{score: score} = State.score_hand(state)
      assert Map.get(score, :ac) == 1
      assert Map.get(score, :bd) == 0
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
        score: %{ac: 0, bd: 0},
        play_order: [:a, :b, :c, :d]
      }

      %State{score: score} = State.score_hand(state)
      assert Map.get(score, :ac) == 1
      assert Map.get(score, :bd) == 0

      state = %State{
        table: %{
          a: "A♥",
          b: "9♠",
          c: "A♦",
          d: "K♥",
        },
        trump: "♣",
        score: %{ac: 0, bd: 0},
        play_order: [:b, :c, :d, :a]
      }
      %State{score: score} = State.score_hand(state)
      assert Map.get(score, :ac) == 0
      assert Map.get(score, :bd) == 1
		end
	end
end
