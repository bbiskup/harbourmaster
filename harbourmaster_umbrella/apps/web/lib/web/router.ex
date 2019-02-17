defmodule Web.Router do
  use Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Web do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
    get("/app", PageController, :app)
  end

  # Other scopes may use custom stacks.
  scope "/api", Web do
    pipe_through(:api)

    get("/docker-engine/", DockerEngineController, :index)
  end
end
