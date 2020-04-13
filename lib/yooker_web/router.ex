defmodule YookerWeb.Router do
  use YookerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", YookerWeb do
    pipe_through :browser

    live "/", LobbyLive
  end

  scope "/game", YookerWeb do
    pipe_through :browser

    live "/", GameLive
  end
end
