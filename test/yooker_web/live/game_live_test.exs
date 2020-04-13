defmodule YookerWeb.GameLiveTest do
  use YookerWeb.ConnCase #figure out if this is needed
  import Phoenix.LiveViewTest
	require Logger

  setup do
    {_result, %{redirect: %{to: route }}} = live(build_conn(), "/game?player=tester")
    %{path: _path, query: query} = URI.parse(route)
    query_params = URI.query_decoder(query) |> Enum.into(%{})

    game_name = Map.get(query_params, "game")
    assert String.match?(game_name, ~r/[A-z]+/)

    {:ok, view, _html} = live(build_conn(), route)
    via_tuple = {:via, Registry, {Yooker.GameRegistry, game_name}}

    {:ok, view: view, via_tuple: via_tuple}
  end

  test "deals cards", %{via_tuple: via_tuple, view: _view} do
    GenServer.call(via_tuple, :game)
    # TODO doesn't actually check if we can deal cards - just ensures there's no errors during setup steps above right now
  end
end
