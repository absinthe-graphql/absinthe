defmodule Absinthe.Mixfile do
  use Mix.Project

  @version "1.4.16"

  def project do
    [
      app: :absinthe,
      version: @version,
      elixir: "~> 1.4",
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
      deps: deps()
    ]
  end

  defp package do
    [
      description: "GraphQL for Elixir",
      files: [
        "lib",
        "src/absinthe_lexer.xrl",
        "src/absinthe_parser.yrl",
        "priv",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        ".formatter.exs"
      ],
      maintainers: [
        "Bruce Williams",
        "Ben Wilson"
      ],
      licenses: ["MIT"],
      links: %{
        Website: "https://absinthe-graphql.org",
        Changelog: "https://github.com/absinthe-graphql/absinthe/blob/v1.4/CHANGELOG.md",
        GitHub: "https://github.com/absinthe-graphql/absinthe"
      }
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:dataloader, "~> 1.0.0", optional: true},
      {:ex_doc, "0.19.0-rc", only: :dev},
      {:benchfella, "~> 0.3.0", only: :dev},
      {:dialyze, "~> 0.2", only: :dev},
      {:decimal, "~> 1.0", optional: true},
      {:phoenix_pubsub, ">= 0.0.0", only: :test},
      {:mix_test_watch, "~> 0.4.1", only: [:test, :dev]}
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
      "guides/ecto.md",
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
      "guides/deprecation.md",
      "guides/adapters.md",
      "guides/complexity-analysis.md",
      "guides/file-uploads.md",
      "guides/client/javascript.md",
      "guides/client/apollo.md",
      "guides/client/relay.md",
      "guides/upgrading/v1.4.md"
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
        Absinthe.Schema.Notation,
        Absinthe.Resolution.Helpers,
        Absinthe.Type,
        Absinthe.Type.Custom,
        Absinthe.Type.Argument,
        Absinthe.Type.BuiltIns,
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
        Absinthe.Middleware.PassParent
      ],
      Subscriptions: [
        Absinthe.Subscription,
        Absinthe.Subscription.Pubsub
      ],
      Extensibility: [
        Absinthe.Pipeline,
        Absinthe.Phase,
        Absinthe.Phase.Validation.Helpers,
        Absinthe.Pipeline.ErrorResult
      ],
      "Document Adapters": [
        Absinthe.Adapter,
        Absinthe.Adapter.LanguageConventions,
        Absinthe.Adapter.Passthrough
      ],
      Execution: [
        Absinthe.Blueprint,
        Absinthe.Blueprint.Execution,
        Absinthe.Traversal,
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
