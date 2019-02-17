defmodule Web.PageController do
  use Web, :controller

  def index(conn, _params) do
    redirect(conn, to: "/app")
  end

  def app(conn, _params) do
    render(conn, "index.html")
  end
end
