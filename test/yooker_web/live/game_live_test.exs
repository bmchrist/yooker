defmodule YookerWeb.GameLiveTest do
  use YookerWeb.ConnCase #figure out if this is needed
  import Phoenix.LiveViewTest
	require Logger

  setup do
    {_result, %{redirect: %{to: route }}} = live(conn, "/")
    assert String.match?(route, ~r/\/?game=[A-z]+/)

    game_name = String.split(route, "=") |> List.last()

    {_result, %{redirect: %{to: route }}} = live(conn, route)
    assert String.match?(route, ~r/\/?game=[A-z]+&player=[A-z]+/)

    {:ok, view, html} = live(conn, route)
    via_tuple = {:via, Registry, {Yooker.GameRegistry, game_name}}

    {:ok, view: view, via_tuple: via_tuple}
  end

  test "deals cards", %{via_tuple: via_tuple, view: view} do
    game = GenServer.call(via_tuple, :game)
     # TODO
  end
end
