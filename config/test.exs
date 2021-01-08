use Mix.Config

config :logger, level: :info

config :logger, :console, metadata: [:request_id]
