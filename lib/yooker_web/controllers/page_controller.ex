defmodule YookerWeb.PageController do
  use YookerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
