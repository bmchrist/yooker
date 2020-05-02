defmodule Yooker.Card do
  @moduledoc """
  A playing card.
  """

  alias Yooker.Card.Suit
  alias Yooker.Card.Value

  require Suit

  @enforce_keys [:suit, :value]

  defstruct [:suit, :value]

  @type t :: %__MODULE__{suit: Suit.t(), value: Value.t()}

  @doc """
  Get color of card.

  ## Examples

      iex> card = %Yooker.Card{suit: :clubs, value: :nine}
      iex> Yooker.Card.color(card)
      :black
      iex> card = %Yooker.Card{suit: :spades, value: :nine}
      iex> Yooker.Card.color(card)
      :black
      iex> card = %Yooker.Card{suit: :diamonds, value: :nine}
      iex> Yooker.Card.color(card)
      :red
      iex> card = %Yooker.Card{suit: :hearts, value: :nine}
      iex> Yooker.Card.color(card)
      :red
  """
  @spec color(t) :: Suit.color()
  def color(%__MODULE__{suit: suit}), do: Suit.color(suit)

  @doc """
  Create card from string.

  ## Examples

      iex> Yooker.Card.from_string("♥A")
      %Yooker.Card{suit: :hearts, value: :ace}
      iex> Yooker.Card.from_string("♣10")
      %Yooker.Card{suit: :clubs, value: :ten}
  """
  @spec from_string(String.t()) :: t
  def from_string(<<suit::binary-size(3), value::binary>>) do
    %__MODULE__{
      suit: Suit.from_string(suit),
      value: Value.from_string(value)
    }
  end

  @doc """
  Get card suit as a string.

  ## Examples

      iex> card = %Yooker.Card{suit: :clubs, value: :nine}
      iex> Yooker.Card.to_suit_string(card)
      "♣"
      iex> card = %Yooker.Card{suit: :spades, value: :nine}
      iex> Yooker.Card.to_suit_string(card)
      "♠"
      iex> card = %Yooker.Card{suit: :diamonds, value: :nine}
      iex> Yooker.Card.to_suit_string(card)
      "♦"
      iex> card = %Yooker.Card{suit: :hearts, value: :nine}
      iex> Yooker.Card.to_suit_string(card)
      "♥"
  """
  @spec to_suit_string(t) :: String.t()
  def to_suit_string(%__MODULE__{suit: suit}), do: Suit.to_string(suit)

  @doc """
  Get card value as a string.

  ## Examples

      iex> card = %Yooker.Card{suit: :clubs, value: :nine}
      iex> Yooker.Card.to_value_string(card)
      "9"
      iex> card = %Yooker.Card{suit: :clubs, value: :ten}
      iex> Yooker.Card.to_value_string(card)
      "10"
      iex> card = %Yooker.Card{suit: :clubs, value: :jack}
      iex> Yooker.Card.to_value_string(card)
      "J"
      iex> card = %Yooker.Card{suit: :clubs, value: :queen}
      iex> Yooker.Card.to_value_string(card)
      "Q"
      iex> card = %Yooker.Card{suit: :clubs, value: :king}
      iex> Yooker.Card.to_value_string(card)
      "K"
      iex> card = %Yooker.Card{suit: :clubs, value: :ace}
      iex> Yooker.Card.to_value_string(card)
      "A"
  """
  @spec to_value_string(t) :: String.t()
  def to_value_string(%__MODULE__{value: value}), do: Value.to_string(value)

  @doc """
  Get suit of card taking into account trump.

  ## Examples

      iex> card = %Yooker.Card{suit: :diamonds, value: :jack}
      iex> Yooker.Card.trump_suit(card, :diamonds)
      :diamonds

      iex> card = %Yooker.Card{suit: :hearts, value: :jack}
      iex> Yooker.Card.trump_suit(card, :diamonds)
      :diamonds

      iex> card = %Yooker.Card{suit: :hearts, value: :ten}
      iex> Yooker.Card.trump_suit(card, :diamonds)
      :hearts

      iex> card = %Yooker.Card{suit: :spades, value: :jack}
      iex> Yooker.Card.trump_suit(card, :diamonds)
      :spades
  """
  @spec trump_suit(t, Suit.t()) :: Suit.t()
  def trump_suit(card, trump)

  def trump_suit(%__MODULE__{suit: suit, value: :jack}, trump)
      when Suit.is_left_suit(suit, trump),
      do: trump

  def trump_suit(%__MODULE__{suit: suit}, _trump), do: suit

  @doc """
  Get score for card taking into account trump and leading suit.

  ## Examples

      # If it's the right bower, it's worth a lot
      iex> card = %Card{suit: :hearts, value: :jack}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      11000

      # If it's the left bower, it's worth a little less
      iex> card = %Card{suit: :diamonds, value: :jack}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      1100

      # Otherwise if it's any trump, it's worth a premium on its face value
      iex> card = %Card{suit: :hearts, value: :ace}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      140
      iex> card = %Card{suit: :hearts, value: :king}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      130
      iex> card = %Card{suit: :hearts, value: :queen}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      120
      iex> card = %Card{suit: :hearts, value: :ten}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      100
      iex> card = %Card{suit: :hearts, value: :nine}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      90

      # Otherwise if it follows suit, it's worth its face value
      iex> card = %Card{suit: :clubs, value: :ace}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      14
      iex> card = %Card{suit: :clubs, value: :king}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      13
      iex> card = %Card{suit: :clubs, value: :queen}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      12
      iex> card = %Card{suit: :clubs, value: :jack}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      11
      iex> card = %Card{suit: :clubs, value: :ten}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      10
      iex> card = %Card{suit: :clubs, value: :nine}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      9

      # Otherwise it's worth 0 - did not follow suit
      iex> card = %Card{suit: :diamonds, value: :ace}
      iex> Yooker.Card.score(card, :clubs, :hearts)
      0
  """
  @spec score(t, Suit.t(), Suit.t()) :: integer()
  def score(card, leading_suit, trump)

  def score(%__MODULE__{suit: suit, value: :jack}, _leading_suit, trump) when suit == trump,
    do: 1000 * Value.face_value(:jack)

  def score(%__MODULE__{suit: suit, value: value}, _leading_suit, trump) when suit == trump,
    do: 10 * Value.face_value(value)

  def score(%__MODULE__{suit: suit, value: :jack}, _leading_suit, trump)
      when Suit.is_left_suit(suit, trump),
      do: 100 * Value.face_value(:jack)

  def score(%__MODULE__{suit: suit, value: value}, leading_suit, _trump)
      when suit == leading_suit,
      do: Value.face_value(value)

  def score(%__MODULE__{}, _leading_suit, _trump), do: 0
end

defimpl String.Chars, for: Yooker.Card do
  alias Yooker.Card

  def to_string(card) do
    "#{Card.to_suit_string(card)}#{Card.to_value_string(card)}"
  end
end

defimpl Phoenix.HTML.Safe, for: Yooker.Card do
  alias Yooker.Card

  def to_iodata(card) do
    "#{Card.to_suit_string(card)}#{Card.to_value_string(card)}"
  end
end
