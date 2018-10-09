defmodule K8sPhoenixWeb.Router do
  use K8sPhoenixWeb, :router

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

  scope "/", K8sPhoenixWeb do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", PageController, :index)
  end

  scope "/api", K8sPhoenixWeb do
    pipe_through(:api)
    get("/health", HealthController, :health)
  end
end
