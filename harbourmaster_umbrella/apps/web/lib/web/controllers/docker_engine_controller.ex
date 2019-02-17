defmodule Web.DockerEngineController do
  use Web, :controller

  def index(conn, _params) do
    :logger.info(IO.inspect(_params))

    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(:get, {'http://localhost:8000/images/json', []}, [], [])

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end
end
