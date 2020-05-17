defmodule Absinthe.Mixfile do
  use Mix.Project

  @version "1.5.1"

  def project do
    [
      app: :absinthe,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      source_url: "https://github.com/absinthe-graphql/absinthe",
      docs: [
        source_ref: "v#{@version}",
        main: "overview",
        logo: "logo.png",
        extra_section: "GUIDES",
        assets: "guides/assets",
        formatters: ["html", "epub"],
        groups_for_modules: groups_for_modules(),
        extras: extras(),
        groups_for_extras: groups_for_extras()
      ],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :dataloader, :decimal, :ex_unit, :inets],
        plt_file: {:no_warn, "priv/plts/absinthe.plt"}
      ]
    ]
  end

  defp package do
    [
      description: "GraphQL for Elixir",
      files: [
        "lib",
        "src/absinthe_parser.yrl",
        "priv",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        ".formatter.exs"
      ],
      maintainers: [
        "Bruce Williams",
        "Ben Wilson",
        "Vince Foley"
      ],
      licenses: ["MIT"],
      links: %{
        Website: "https://absinthe-graphql.org",
        Changelog: "https://github.com/absinthe-graphql/absinthe/blob/master/CHANGELOG.md",
        GitHub: "https://github.com/absinthe-graphql/absinthe"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5"},
      {:telemetry, "~> 0.4.0"},
      {:dataloader, "~> 1.0.0", optional: true},
      {:decimal, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.21.0", only: :dev},
      {:benchee, ">= 1.0.0", only: :dev},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:phoenix_pubsub, ">= 0.0.0", only: :test},
      {:mix_test_watch, "~> 0.4.1", only: [:test]}
    ]
  end

  #
  # Documentation
  #

  defp extras do
    [
      "guides/introduction/overview.md",
      "guides/introduction/installation.md",
      "guides/introduction/learning.md",
      "guides/introduction/community.md",
      "guides/tutorial/start.md",
      "guides/tutorial/our-first-query.md",
      "guides/tutorial/query-arguments.md",
      "guides/tutorial/mutations.md",
      "guides/tutorial/complex-arguments.md",
      "guides/tutorial/conclusion.md",
      "guides/schemas.md",
      "guides/plug-phoenix.md",
      "guides/middleware-and-plugins.md",
      "guides/errors.md",
      "guides/batching.md",
      "guides/dataloader.md",
      "guides/context-and-authentication.md",
      "guides/subscriptions.md",
      "guides/custom-scalars.md",
      "guides/importing-types.md",
      "guides/importing-fields.md",
      "guides/variables.md",
      "guides/introspection.md",
      "guides/telemetry.md",
      "guides/deprecation.md",
      "guides/adapters.md",
      "guides/complexity-analysis.md",
      "guides/file-uploads.md",
      "guides/testing.md",
      "guides/client/javascript.md",
      "guides/client/apollo.md",
      "guides/client/relay.md",
      "guides/upgrading/v1.4.md",
      "guides/upgrading/v1.5.md"
    ]
  end

  defp groups_for_extras do
    [
      Introduction: ~r/guides\/introduction\/.*/,
      Tutorial: ~r/guides\/tutorial\/.*/,
      Topics: ~r/guides\/[^\/]+\.md/,
      "Client Guides": ~r/guides\/client\/.*/,
      "Upgrade Guides": ~r/guides\/upgrading\/.*/
    ]
  end

  defp groups_for_modules do
    # Ungrouped:
    # - Absinthe

    [
      "Schema Definition and Types": [
        Absinthe.Schema,
        Absinthe.Schema.Hydrator,
        Absinthe.Schema.Notation,
        Absinthe.Schema.Prototype,
        Absinthe.Resolution.Helpers,
        Absinthe.Type,
        Absinthe.Type.Custom,
        Absinthe.Type.Argument,
        Absinthe.Type.Custom,
        Absinthe.Type.Directive,
        Absinthe.Type.Enum,
        Absinthe.Type.Enum.Value,
        Absinthe.Type.Field,
        Absinthe.Type.InputObject,
        Absinthe.Type.Interface,
        Absinthe.Type.List,
        Absinthe.Type.NonNull,
        Absinthe.Type.Object,
        Absinthe.Type.Scalar,
        Absinthe.Type.Union
      ],
      "Middleware and Plugins": [
        Absinthe.Middleware,
        Absinthe.Plugin,
        Absinthe.Middleware.Async,
        Absinthe.Middleware.Batch,
        Absinthe.Middleware.Dataloader,
        Absinthe.Middleware.MapGet,
        Absinthe.Middleware.PassParent,
        Absinthe.Middleware.Telemetry
      ],
      Subscriptions: [
        Absinthe.Subscription,
        Absinthe.Subscription.Pubsub,
        Absinthe.Subscription.Local
      ],
      Extensibility: [
        Absinthe.Pipeline,
        Absinthe.Phase,
        Absinthe.Phase.Document.Context,
        Absinthe.Phase.Telemetry,
        Absinthe.Pipeline.ErrorResult
      ],
      "Document Adapters": [
        Absinthe.Adapter,
        Absinthe.Adapter.LanguageConventions,
        Absinthe.Adapter.Passthrough,
        Absinthe.Adapter.StrictLanguageConventions,
        Absinthe.Adapter.Underscore
      ],
      Execution: [
        Absinthe.Blueprint,
        Absinthe.Blueprint.Execution,
        Absinthe.Resolution,
        Absinthe.Complexity
      ],
      Introspection: [
        Absinthe.Introspection
      ],
      Testing: [
        Absinthe.Test
      ],
      Utilities: [
        Absinthe.Logger,
        Absinthe.Utils,
        Absinthe.Utils.Suggestion
      ]
    ]
  end
end
