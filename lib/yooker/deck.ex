defmodule Yooker.Deck do
  @moduledoc """
  A module for interacting with a deck of cards.
  """

  alias Yooker.Card

  @type t :: [Card.t()]

  @doc ~S"""
  Setup a new deck.

  ## Examples

      iex> Yooker.Deck.new()
      [
        %Yooker.Card{suit: :clubs, value: :nine},
        %Yooker.Card{suit: :clubs, value: :ten},
        %Yooker.Card{suit: :clubs, value: :jack},
        %Yooker.Card{suit: :clubs, value: :king},
        %Yooker.Card{suit: :clubs, value: :queen},
        %Yooker.Card{suit: :clubs, value: :ace},
        %Yooker.Card{suit: :diamonds, value: :nine},
        %Yooker.Card{suit: :diamonds, value: :ten},
        %Yooker.Card{suit: :diamonds, value: :jack},
        %Yooker.Card{suit: :diamonds, value: :king},
        %Yooker.Card{suit: :diamonds, value: :queen},
        %Yooker.Card{suit: :diamonds, value: :ace},
        %Yooker.Card{suit: :hearts, value: :nine},
        %Yooker.Card{suit: :hearts, value: :ten},
        %Yooker.Card{suit: :hearts, value: :jack},
        %Yooker.Card{suit: :hearts, value: :king},
        %Yooker.Card{suit: :hearts, value: :queen},
        %Yooker.Card{suit: :hearts, value: :ace},
        %Yooker.Card{suit: :spades, value: :nine},
        %Yooker.Card{suit: :spades, value: :ten},
        %Yooker.Card{suit: :spades, value: :jack},
        %Yooker.Card{suit: :spades, value: :king},
        %Yooker.Card{suit: :spades, value: :queen},
        %Yooker.Card{suit: :spades, value: :ace}
      ]

  """
  @spec new() :: t
  def new do
    for suit <- Card.Suit.all(), value <- Card.Value.all(), do: %Card{suit: suit, value: value}
  end

  @doc ~S"""
  Shuffle the deck.

  ## Examples

      iex> :rand.seed(:exsss, {1, 2, 3})
      iex> deck = Yooker.Deck.new()
      iex> Yooker.Deck.shuffle(deck)
      [
        %Yooker.Card{suit: :spades, value: :ace},
        %Yooker.Card{suit: :hearts, value: :ace},
        %Yooker.Card{suit: :spades, value: :jack},
        %Yooker.Card{suit: :diamonds, value: :king},
        %Yooker.Card{suit: :spades, value: :nine},
        %Yooker.Card{suit: :spades, value: :queen},
        %Yooker.Card{suit: :clubs, value: :jack},
        %Yooker.Card{suit: :hearts, value: :king},
        %Yooker.Card{suit: :clubs, value: :ten},
        %Yooker.Card{suit: :clubs, value: :queen},
        %Yooker.Card{suit: :clubs, value: :nine},
        %Yooker.Card{suit: :hearts, value: :queen},
        %Yooker.Card{suit: :diamonds, value: :nine},
        %Yooker.Card{suit: :clubs, value: :king},
        %Yooker.Card{suit: :spades, value: :king},
        %Yooker.Card{suit: :diamonds, value: :ace},
        %Yooker.Card{suit: :hearts, value: :nine},
        %Yooker.Card{suit: :clubs, value: :ace},
        %Yooker.Card{suit: :diamonds, value: :queen},
        %Yooker.Card{suit: :diamonds, value: :ten},
        %Yooker.Card{suit: :diamonds, value: :jack},
        %Yooker.Card{suit: :spades, value: :ten},
        %Yooker.Card{suit: :hearts, value: :jack},
        %Yooker.Card{suit: :hearts, value: :ten}
      ]
  """
  @spec shuffle(t) :: t
  defdelegate shuffle(deck), to: Enum

  @doc ~S"""
  Take cards from the deck.

  ## Examples

      iex> deck = Yooker.Deck.new()
      iex> {cards, deck} = Yooker.Deck.take(deck, 3)
      {
        [
          %Yooker.Card{suit: :clubs, value: :nine},
          %Yooker.Card{suit: :clubs, value: :ten},
          %Yooker.Card{suit: :clubs, value: :jack},
        ],
        [
          %Yooker.Card{suit: :clubs, value: :king},
          %Yooker.Card{suit: :clubs, value: :queen},
          %Yooker.Card{suit: :clubs, value: :ace},
          %Yooker.Card{suit: :diamonds, value: :nine},
          %Yooker.Card{suit: :diamonds, value: :ten},
          %Yooker.Card{suit: :diamonds, value: :jack},
          %Yooker.Card{suit: :diamonds, value: :king},
          %Yooker.Card{suit: :diamonds, value: :queen},
          %Yooker.Card{suit: :diamonds, value: :ace},
          %Yooker.Card{suit: :hearts, value: :nine},
          %Yooker.Card{suit: :hearts, value: :ten},
          %Yooker.Card{suit: :hearts, value: :jack},
          %Yooker.Card{suit: :hearts, value: :king},
          %Yooker.Card{suit: :hearts, value: :queen},
          %Yooker.Card{suit: :hearts, value: :ace},
          %Yooker.Card{suit: :spades, value: :nine},
          %Yooker.Card{suit: :spades, value: :ten},
          %Yooker.Card{suit: :spades, value: :jack},
          %Yooker.Card{suit: :spades, value: :king},
          %Yooker.Card{suit: :spades, value: :queen},
          %Yooker.Card{suit: :spades, value: :ace}
        ]
      }
  """
  @spec take(t, integer) :: {cards :: t, deck :: t}
  defdelegate take(deck, num), to: Enum, as: :split
end
