# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :moola,
  ecto_repos: [Moola.Repo]

# Configures the endpoint
config :moola, MoolaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "BBLVTdgBPp0Tpbvq9a/R3y40mn6tRM+btTFmxYw69Ol2IcrV1Dw8vxzm6ydTN4TI",
  render_errors: [view: MoolaWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Moola.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure GDAX API credentials
config :ex_gdax, api_key:        System.get_env("GDAX_API_KEY"),
                 api_secret:     System.get_env("GDAX_API_SECRET"),
                 api_passphrase: System.get_env("GDAX_API_PASSPHRASE")

# Configure Coinbase API credentials
config :coinbase_ex,  api_key:        System.get_env("COINBASE_API_KEY"),
                      api_secret:     System.get_env("COINBASE_API_SECRET"),
                      api_url:        "https://api.coinbase.com",
                      version:        "2017-10-01"
                      
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
