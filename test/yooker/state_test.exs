defmodule Yooker.StateTest do
	alias Yooker.State
	use ExUnit.Case
	doctest Yooker.State

	describe "score_hand/3" do
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
