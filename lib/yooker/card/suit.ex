defmodule Yooker.Card.Suit do
  @moduledoc """
  A card suit.
  """
  @suits [:clubs, :diamonds, :hearts, :spades]

  @type t :: unquote(Enum.reduce(@suits, &{:|, [], [&1, &2]}))

  @type color :: :black | :red

  @doc """
  Guard for checking offsuits.

  ## Examples

      iex> Yooker.Card.Suit.is_left_suit(:clubs, :spades)
      true

      iex> Yooker.Card.Suit.is_left_suit(:spades, :clubs)
      true

      iex> Yooker.Card.Suit.is_left_suit(:hearts, :diamonds)
      true

      iex> Yooker.Card.Suit.is_left_suit(:diamonds, :hearts)
      true
  """
  defguard is_left_suit(left, right)
           when (left == :clubs and right == :spades) or
                  (left == :spades and right == :clubs) or
                  (left == :hearts and right == :diamonds) or
                  (left == :diamonds and right == :hearts)

  @doc """
  List possible suits.

  ## Examples

      iex> Yooker.Card.Suit.all()
      [:clubs, :diamonds, :hearts, :spades]
  """
  @spec all() :: [t]
  def all, do: @suits

  @doc """
  Get color of suit.

  ## Examples

      iex> Yooker.Card.Suit.color(:clubs)
      :black
      iex> Yooker.Card.Suit.color(:spades)
      :black
      iex> Yooker.Card.Suit.color(:diamonds)
      :red
      iex> Yooker.Card.Suit.color(:hearts)
      :red
  """
  @spec color(t) :: color
  def color(suit)

  def color(:clubs), do: :black
  def color(:spades), do: :black
  def color(:diamonds), do: :red
  def color(:hearts), do: :red

  @doc """
  Get suit as a string.

  ## Examples

      iex> Yooker.Card.Suit.to_string(:clubs)
      "♣"
      iex> Yooker.Card.Suit.to_string(:spades)
      "♠"
      iex> Yooker.Card.Suit.to_string(:diamonds)
      "♦"
      iex> Yooker.Card.Suit.to_string(:hearts)
      "♥"
  """
  @spec to_string(t) :: String.t()
  def to_string(:clubs), do: "♣"
  def to_string(:spades), do: "♠"
  def to_string(:diamonds), do: "♦"
  def to_string(:hearts), do: "♥"

  @doc """
  convert suit from string.

  ## Examples

      iex> Yooker.Card.Suit.from_string("♣")
      :clubs
      iex> Yooker.Card.Suit.from_string("♠")
      :spades
      iex> Yooker.Card.Suit.from_string("♦")
      :diamonds
      iex> Yooker.Card.Suit.from_string("♥")
      :hearts
  """
  @spec from_string(String.t()) :: t
  def from_string("♣"), do: :clubs
  def from_string("♠"), do: :spades
  def from_string("♦"), do: :diamonds
  def from_string("♥"), do: :hearts
end
