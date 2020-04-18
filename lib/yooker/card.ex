defmodule Yooker.Card do
  @moduledoc """
    A playing card.
  """
  @suits [:clubs, :diamonds, :hearts, :spades]

  @values [:nine, :ten, :jack, :king, :queen, :ace]

  @enforce_keys [:suit, :value]

  defstruct [:suit, :value]

  @type t :: %__MODULE__{suit: suit, value: value}

  @type suit :: unquote(Enum.reduce(@suits, &{:|, [], [&1, &2]}))

  @type value :: unquote(Enum.reduce(@values, &{:|, [], [&1, &2]}))

  @doc ~S"""
  List possible suits.

  ## Examples

      iex> Yooker.Card.suits()
      [:clubs, :diamonds, :hearts, :spades]
  """
  @spec suits() :: [suit]
  def suits, do: @suits

  @doc ~S"""
  List possible values.

  ## Examples

      iex> Yooker.Card.values()
      [:nine, :ten, :jack, :king, :queen, :ace]
  """
  @spec values() :: [value]
  def values, do: @values

  @doc ~S"""
  Determine offsuit for a given suit.

  ## Examples

      iex> Yooker.Card.offsuit(:clubs)
      :spades
      iex> Yooker.Card.offsuit(:spades)
      :clubs
      iex> Yooker.Card.offsuit(:diamonds)
      :hearts
      iex> Yooker.Card.offsuit(:hearts)
      :diamonds
  """
  @spec offsuit(suit) :: suit
  def offsuit(suit)

  # Black suits
  def offsuit(:clubs), do: :spades
  def offsuit(:spades), do: :clubs

  # Red suits
  def offsuit(:hearts), do: :diamonds
  def offsuit(:diamonds), do: :hearts
end

