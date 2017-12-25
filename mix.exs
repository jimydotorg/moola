defmodule Moola.Mixfile do
  use Mix.Project

  def project do
    [
      app: :moola,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Moola.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 2.1"},
      {:ecto_enum, "~> 1.0"},
      {:decimal, "~> 1.0"},

      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      
      {:edeliver, "~> 1.4.3"},
      {:distillery, "~> 1.4"},

      {:websockex, "~> 0.4.0"},
      {:comeonin, "~> 4.0"},
      {:bcrypt_elixir, "~> 0.12.0"},
      {:hashids, "~> 2.0"},
      {:httpoison, "~> 0.13", override: true},
      {:ex_twilio, "~> 0.5.0"},

      {:ex_gdax, "~> 0.1"},
      {:coinbase_ex, github: "jimydotorg/coinbase_ex"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.dump", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"],

      # Custom
      "db.migrate": ["ecto.migrate", "ecto.dump"],
      "db.rollback": ["ecto.rollback", "ecto.dump"],
      "db.reset": ["ecto.reset"],
    ]
  end
end
