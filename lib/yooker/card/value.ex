defmodule Yooker.Card.Value do
  @moduledoc """
  A card value.
  """
  @values [:nine, :ten, :jack, :king, :queen, :ace]

  @type t :: unquote(Enum.reduce(@values, &{:|, [], [&1, &2]}))

  @doc """
  List possible values.

  ## Examples

      iex> Yooker.Card.Value.all()
      [:nine, :ten, :jack, :king, :queen, :ace]
  """
  @spec all() :: [t]
  def all, do: @values

  @doc """
  Get card value as a string.

  ## Examples

      iex> Yooker.Card.Value.to_string(:nine)
      "9"
      iex> Yooker.Card.Value.to_string(:ten)
      "10"
      iex> Yooker.Card.Value.to_string(:jack)
      "J"
      iex> Yooker.Card.Value.to_string(:queen)
      "Q"
      iex> Yooker.Card.Value.to_string(:king)
      "K"
      iex> Yooker.Card.Value.to_string(:ace)
      "A"
  """
  @spec to_string(t) :: String.t()
  def to_string(:nine), do: "9"
  def to_string(:ten), do: "10"
  def to_string(:jack), do: "J"
  def to_string(:queen), do: "Q"
  def to_string(:king), do: "K"
  def to_string(:ace), do: "A"

  @doc """
  Get card value from string.

  ## Examples

      iex> Yooker.Card.Value.from_string("9")
      :nine
      iex> Yooker.Card.Value.from_string("10")
      :ten
      iex> Yooker.Card.Value.from_string("J")
      :jack
      iex> Yooker.Card.Value.from_string("Q")
      :queen
      iex> Yooker.Card.Value.from_string("K")
      :king
      iex> Yooker.Card.Value.from_string("A")
      :ace
  """
  @spec from_string(String.t()) :: t
  def from_string("9"), do: :nine
  def from_string("10"), do: :ten
  def from_string("J"), do: :jack
  def from_string("Q"), do: :queen
  def from_string("K"), do: :king
  def from_string("A"), do: :ace

  @doc """
  Get numeric face value.

  ## Examples

      iex> Yooker.Card.Value.face_value(:nine)
      9
      iex> Yooker.Card.Value.face_value(:ten)
      10
      iex> Yooker.Card.Value.face_value(:jack)
      11
      iex> Yooker.Card.Value.face_value(:queen)
      12
      iex> Yooker.Card.Value.face_value(:king)
      13
      iex> Yooker.Card.Value.face_value(:ace)
      14
  """
  @spec face_value(t) :: integer()
  def face_value(:nine), do: 9
  def face_value(:ten), do: 10
  def face_value(:jack), do: 11
  def face_value(:queen), do: 12
  def face_value(:king), do: 13
  def face_value(:ace), do: 14
end
