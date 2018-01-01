defmodule MoolaWeb.Router do
  use MoolaWeb, :router

  pipeline :api_init do
    plug :accepts, ["json"]
    plug MoolaWeb.Plugs.ExtractClient
    plug MoolaWeb.Plugs.ExtractUser
  end

  pipeline :api_requires_client do
    plug :accepts, ["json"]
    plug MoolaWeb.Plugs.ExtractClient
    plug MoolaWeb.Plugs.RequireClient
    plug MoolaWeb.Plugs.ExtractUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MoolaWeb do
    pipe_through :api
  end

  # No tokens required
  scope "/", MoolaWeb do
    pipe_through :api_init
    pipe_through MoolaWeb.Plugs.Logger

    post "/init", AuthController, :init

    # Unsubscribing from emails/txt does not require user to be logged in.
    post "/email/prefs", XXXController, :test
    post "/sms/prefs", XXXController, :test
  end

  # Valid client required
  scope "/", MoolaWeb do
    pipe_through :api_requires_client
    pipe_through MoolaWeb.Plugs.Logger

    resources "/gdax", GdaxController, only: [:index, :show]
    resources "/coinbase", CoinbaseController, only: [:index, :show]

  end

end
