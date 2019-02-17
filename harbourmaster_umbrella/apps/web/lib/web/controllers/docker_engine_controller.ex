defmodule Web.DockerEngineController do
  use Web, :controller

  def index(conn, params) do
    :logger.info(IO.inspect(params))

    docker_api_url_prefix = "http://localhost:8000"

    [path, query] =
      case String.split(params["url"], "?", parts: 2) do
        [url, query] ->
          IO.puts("URL+query #{url} #{query}")
          [url, URI.encode(query)]

        [url] ->
          IO.puts("Only URL #{url}")
          [url, '']
      end

    docker_api_url =
      String.to_char_list("#{docker_api_url_prefix}#{path}?") ++ :http_uri.encode(query)

    # :logger.debug("docker_api_url #{IO.inspect(docker_api_url)}")

    {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} =
      :httpc.request(:get, {docker_api_url, []}, [], [])

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, body)
  end
end
