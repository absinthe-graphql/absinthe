defmodule Absinthe.Mixfile do
  use Mix.Project

  @version "1.3.2"

  def project do
    [app: :absinthe,
     version: @version,
     elixir: "~> 1.4",
     elixirc_paths: elixirc_paths(Mix.env),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     source_url: "https://github.com/absinthe-graphql/absinthe",
     docs: [source_ref: "v#{@version}", main: "Absinthe"],
     deps: deps()
    ]
  end

  defp package do
    [description: "GraphQL for Elixir",
     files: ["lib", "src", "priv", "mix.exs", "README*"],
     maintainers: ["Bruce Williams", "Ben Wilson"],
     licenses: ["BSD"],
     links: %{github: "https://github.com/absinthe-graphql/absinthe"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:ex_spec, "~> 2.0.0", only: :test},
      {:ex_doc, "~> 0.14", only: :dev},
      {:benchfella, "~> 0.3.0", only: :dev},
      {:dialyze, "~> 0.2", only: :dev},
      {:mix_test_watch, "~> 0.4.0", only: [:test, :dev]}
    ]
  end
end
