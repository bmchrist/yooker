# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :yooker, YookerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "x3LAoH1SH9xMHyjPNpShE7xrwMTu5zLvNknMVaHuZEK6rnrO/dwthfIg+SP33ZXN",
  render_errors: [view: YookerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Yooker.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "dcrAFBLTxJYTDXWsJqRf4ju7C7pOqdSX"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
