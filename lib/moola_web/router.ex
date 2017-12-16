defmodule MoolaWeb.Router do
  use MoolaWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", MoolaWeb do
    pipe_through :api
  end
end
