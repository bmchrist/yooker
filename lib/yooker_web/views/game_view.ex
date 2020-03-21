defmodule YookerWeb.GameView do
  use YookerWeb, :view

  # TODO(bmchrist) no idea if this is best practice for a view - here be code smells

  def get_own_hand do
    # TODO(bmchrist): stub
    # Should return current player's hand, and # of cards for other players
    [
      %{ suit: "hearts", value: "queen" },
      %{ suit: "spades", value: "ace" },
      %{ suit: "hearts", value: "jack" },
      %{ suit: "clubs", value: "jack" },
      %{ suit: nil, value: nil } # card already played
    ]
  end

  def get_left_player_remaining_cards do
    # TODO(bmchrist): stub: returns remaining cards
    3 
  end

  def get_across_player_remaining_cards do
    # TODO(bmchrist): stub: returns remaining cards
    4 
  end

  def get_right_player_remaining_cards do
    # TODO(bmchrist): stub: returns remaining cards
    4 
  end

  def get_table do
    # TODO(bmchrist): stub
    %{
      a: %{ suit: "hearts", value: "nine" },
      b: %{ suit: nil, value: nil }, # has not yet played
      c: %{ suit: nil, value: nil }, # has not yet played
      d: %{ suit: nil, value: nil } # has not yet played
    }
  end

  # Player that led or should lead this hand
  def get_leader do
    # TODO(bmchrist): stub
    "a"
  end

  # Lets the player see what trump is
  def get_trump do
    # TODO(bmchrist): stub
    "hearts"
  end
end
